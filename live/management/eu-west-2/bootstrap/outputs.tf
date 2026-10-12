output "bucket_name" {
  description = "Name of the Terraform state bucket."
  value       = module.state_bucket.bucket_name
}

output "bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = module.state_bucket.bucket_arn
}
