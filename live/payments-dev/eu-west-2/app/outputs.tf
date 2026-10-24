output "url" {
  description = "PyGoat through CloudFront"
  value       = var.enable_cloudfront ? "https://${module.edge.domain_name}" : null
}

output "test_url" {
  description = "Test-only public ALB"
  value       = var.public_alb_for_operator ? "http://${module.alb.dns_name}" : null
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "static_bucket" {
  value = module.edge.static_bucket
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "db_secret_arn" {
  value = module.postgres.master_user_secret_arn
}

output "cluster" {
  value = module.service.cluster_name
}

output "service" {
  value = module.service.service_name
}

output "log_group" {
  value = module.service.log_group_name
}
