output "address" {
  description = "Hostname of the instance"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "arn" {
  description = "Instance ARN, for backup selections"
  value       = aws_db_instance.this.arn
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding username and password"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "Instance security group ID"
  value       = aws_security_group.this.id
}
