# # backendはS3で管理
# terraform {
#   backend "s3" {
#     bucket = "state-bucket-ito-20260104"
#     key    = "stg/data-stores/mysql/terraform.tfstate"
#     region = "ap-northeast-1"

#     use_lockfile = true
#   }
# }

# provider "aws" {
#   region = "ap-northeast-1" # 東京リージョン
# }

# variable "db_username" {
#   description = "データベースのユーザー名"
#   type        = string
#   sensitive   = true
# }

# variable "db_password" {
#   description = "データベースのパスワード"
#   type        = string
#   sensitive   = true
# }

# # MySQL RDSインスタンス
# resource "aws_db_instance" "example" {
#   identifier_prefix   = "terraform-example-"
#   engine              = "mysql"
#   allocated_storage   = 10
#   instance_class      = "db.t3.micro"
#   skip_final_snapshot = true
#   db_name             = "example_database"

#   username = var.db_username
#   password = var.db_password
# }
