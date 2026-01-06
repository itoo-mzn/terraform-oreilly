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

  cluster_name           = "stg-webserver-cluster"
  db_remote_state_bucket = "state-bucket-ito-20260104"
  db_remote_state_key    = "stg/services/webserver-cluster/terraform.tfstate"
}
