# data: すでに存在するリソースを参照
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# stateファイルを読み取る
# data "terraform_remote_state" "db" {
#   backend = "s3"
#   config = {
#     bucket = var.db_remote_state_bucket
#     key    = var.db_remote_state_key
#     region = "ap-northeast-1"
#   }
# }

# ローカル変数（valiable.tfには入力変数を定義）
locals {
  http_port = 80
  any_port  = 0

  any_protocol = "-1"
  tcp_protocol = "tcp"

  all_ips = ["0.0.0.0/0"]
}

# ALB
resource "aws_lb" "example" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# セキュリティグループ ALB用
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# ALBリスナー（受け付けるポートとプロトコルの設定）
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

# ALBリスナールール
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  # ターゲットグループへの転送設定
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# ALBターゲットグループ（ALBからトラフィックを受け、EC2インスタンスに振り分ける）
resource "aws_lb_target_group" "asg" {
  name     = var.cluster_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  # ヘルスチェック（ターゲットグループは、ヘルスチェックが通ったインスタンスにのみトラフィックを送る）
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# オートスケーリンググループ（EC2インスタンスの自動スケーリング設定）
resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  # ALBのターゲットグループ
  target_group_arns = [aws_lb_target_group.asg.arn]

  # ヘルスチェックにターゲットグループのヘルスチェック結果を利用
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true # インスタンス起動時にタグを付与
  }

  # dynamic: for_eachを利用
  dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ALBで起動するインスタンスの設定
resource "aws_launch_template" "example" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = "ami-0f415cc2783de6675"
  instance_type = var.instance_type
  # ALB用セキュリティグループに所属させる
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    server_port = var.server_port
    # db_address  = data.terraform_remote_state.db.outputs.db_address
    # db_port     = data.terraform_remote_state.db.outputs.db_port
  }))

  # この起動設定（aws_launch_template）をASGが参照していることで、これを変更したときに削除ができずにapplyに失敗することを解決するため
  # 新しいものを作成したあとに古いものを削除する設定
  lifecycle {
    create_before_destroy = true
  }
}

# セキュリティグループ インスタンス用
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_server_http_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# 指定時間にサーバー台数を増減するスケジュール設定
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  autoscaling_group_name = aws_autoscaling_group.example.name

  scheduled_action_name = "scale_out_during_business_hours"
  min_size              = 2
  max_size              = 10
  # 希望する容量
  desired_capacity = 10
  # 毎日9時にスケールアウト（UTCなので実際のビジネス稼働時間とは異なるが面倒なので書籍のまま）
  recurrence = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  autoscaling_group_name = aws_autoscaling_group.example.name

  scheduled_action_name = "scale_in_at_night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 18 * * *"
}
