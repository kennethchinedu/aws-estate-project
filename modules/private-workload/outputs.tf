output "instance_id" {
  description = "Instance ID, for SSM sessions and commands"
  value       = aws_instance.this.id
}

output "role_arn" {
  description = "Instance role ARN"
  value       = aws_iam_role.this.arn
}

output "security_group_id" {
  description = "Instance security group ID"
  value       = aws_security_group.this.id
}
