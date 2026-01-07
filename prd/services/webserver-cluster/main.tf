# backendはS3で管理
terraform {
  backend "s3" {
    bucket = "state-bucket-ito-20260104"
    key    = "prd/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-1"

    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "prd-webserver-cluster"

  db_remote_state_bucket = "state-bucket-ito-20260104"
  db_remote_state_key    = "prd/services/webserver-cluster/terraform.tfstate"

  instance_type = "t2.snall"
  min_size      = 4
  max_size      = 20
}
