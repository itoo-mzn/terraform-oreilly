output "s3_bucket_arn" {
  description = "ステート管理用S3"
  value       = aws_s3_bucket.terraform_state.arn
}
