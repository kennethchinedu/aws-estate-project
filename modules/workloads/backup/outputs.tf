output "vault_name" {
  description = "Backup vault name"
  value       = aws_backup_vault.this.name
}

output "vault_arn" {
  description = "Backup vault ARN"
  value       = aws_backup_vault.this.arn
}
