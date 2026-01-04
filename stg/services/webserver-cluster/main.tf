provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

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

# ALB
resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# セキュリティグループ ALB用
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALBリスナー（受け付けるポートとプロトコルの設定）
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
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
  name     = "terraform-asg-example"
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

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true # インスタンス起動時にタグを付与
  }
}

# ALBで起動するインスタンスの設定
resource "aws_launch_template" "example" {
  name_prefix   = "terraform-example-"
  image_id      = "ami-0f415cc2783de6675"
  instance_type = "t2.micro"
  # ALB用セキュリティグループに所属させる
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
                #!/bin/bash
                echo "Hello, world" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
  )

  # この起動設定（aws_launch_template）をASGが参照していることで、これを変更したときに削除ができずにapplyに失敗することを解決するため
  # 新しいものを作成したあとに古いものを削除する設定
  lifecycle {
    create_before_destroy = true
  }
}

# セキュリティグループ インスタンス用
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
