output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "ロードバランサーのドメイン名"
}

output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "webサーバーのオートスケーリンググループ名"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALBのセキュリティグループID"
}
