output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "ロードバランサーのドメイン名"
}

output "asg_name" {
  value       = aws_autoscaling_group.webserver_asg.name
  description = "webサーバーのオートスケーリンググループ名"
}
