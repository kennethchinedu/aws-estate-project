output "arn" {
  description = "Load balancer ARN"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "Load balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "security_group_id" {
  description = "Load balancer security group ID"
  value       = aws_security_group.this.id
}

# Available once the listener exists: ECS rejects a target group without a load balancer
output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.this.arn

  depends_on = [aws_lb_listener.http]
}
