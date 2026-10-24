output "domain_name" {
  description = "CloudFront domain name, null without a distribution"
  value       = var.create_distribution ? aws_cloudfront_distribution.this[0].domain_name : null
}

output "web_acl_arn" {
  description = "WAF web ACL ARN"
  value       = aws_wafv2_web_acl.this.arn
}

output "static_bucket" {
  description = "Bucket for static files"
  value       = aws_s3_bucket.static.id
}
