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
  source = "../../../../modules/services/webserver-cluster"

  cluster_name = "stg-webserver-cluster"

  ami                = "ami-0f415cc2783de6675"
  server_return_text = "New server text"

  db_remote_state_bucket = "state-bucket-ito-20260104"
  db_remote_state_key    = "stg/services/webserver-cluster/terraform.tfstate"

  instance_type      = "t2.micro"
  min_size           = 2
  max_size           = 10
  enable_autoscaling = false

  custom_tags = {
    # このタグを設定しているリソースはどのチームが管理を担当しているのか
    Owner = "team-foo"
    # このリソースがTerraformで構築されたことを示す（手動変更を避けるため）
    DeployedBy = "terraform"
  }
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
