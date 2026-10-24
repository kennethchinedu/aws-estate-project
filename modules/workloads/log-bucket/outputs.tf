output "id" {
  description = "Bucket name"
  value       = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_policy.this]
}

output "arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.this.arn

  depends_on = [aws_s3_bucket_policy.this]
}

output "alb_log_prefix" {
  description = "Key prefix for ALB access logs"
  value       = var.alb_log_prefix
}
