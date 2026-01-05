provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"
}
