# backendはS3で管理
terraform {
  backend "s3" {
    bucket = "state-bucket-ito-20260104"
    key    = "stg/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-1"

    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "stg-webserver-cluster"

  db_remote_state_bucket = "state-bucket-ito-20260104"
  db_remote_state_key    = "stg/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 10

  custom_tags = {
    # このタグを設定しているリソースはどのチームが管理を担当しているのか
    Owner = "team-foo"
    # このリソースがTerraformで構築されたことを示す（手動変更を避けるため）
    DeployedBy = "terraform"
  }
}

# 指定時間にサーバー台数を増減するスケジュール設定
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  autoscaling_group_name = module.webserver-cluster.asg_name

  scheduled_action_name = "scale_out_during_business_hours"
  min_size              = 2
  max_size              = 10
  # 希望する容量
  desired_capacity = 10
  # 毎日9時にスケールアウト（UTCなので実際のビジネス稼働時間とは異なるが面倒なので書籍のまま）
  recurrence = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  autoscaling_group_name = module.webserver-cluster.asg_name

  scheduled_action_name = "scale_in_at_night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 18 * * *"
}

# stg環境のみ、ALBのセキュリティグループに対してテスト用のポート12345番へのアクセスを許可
resource "aws_security_group_rule" "allow_testing_inbound" {
  type              = "ingress"
  security_group_id = module.webserver-cluster.alb_security_group_id

  from_port   = 12345
  to_port     = 12345
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
