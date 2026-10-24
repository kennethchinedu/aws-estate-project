output "repository_url" {
  description = "Repository URL, without a tag"
  value       = aws_ecr_repository.this.repository_url
}

output "arn" {
  description = "Repository ARN"
  value       = aws_ecr_repository.this.arn
}
