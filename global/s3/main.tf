# NOTE: S3のリソース作成後にbackend設定を行うこと
terraform {
  backend "s3" {
    bucket = "state-bucket-ito-20260104"
    key    = "global/s3/terraform.tfstate"
    region = "ap-northeast-1"

    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# stateファイル保存用S3バケット
resource "aws_s3_bucket" "terraform_state" {
  bucket = "state-bucket-ito-20260104"

  lifecycle {
    # 誤って削除するのを防止
    prevent_destroy = true
  }
}

# stateファイルのバージョニング履歴を保存
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# サーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3はデフォでプライベートだが、明示的にパブリックアクセスをブロック
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
