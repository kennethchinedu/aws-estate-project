variable "name" {
  description = "Name prefix for the edge resources"
  type        = string
}

variable "create_distribution" {
  description = "Create the CloudFront distribution (requires an account verified for CloudFront)"
  type        = bool
  default     = true
}

variable "alb_arn" {
  description = "Internal ALB reached through the VPC origin"
  type        = string
}

variable "alb_dns_name" {
  description = "Internal ALB DNS name"
  type        = string
}

variable "static_path" {
  description = "URL path and key prefix served from the static bucket"
  type        = string
  default     = "static"
}

variable "allowed_ip_cidrs" {
  description = "Only source ranges WAF lets through"
  type        = list(string)
}

variable "rate_limit" {
  description = "Requests per source IP per 5 minutes"
  type        = number
  default     = 300
}

variable "managed_rule_groups" {
  description = "AWS managed rule groups, in evaluation order"
  type        = list(string)
  default = [
    "AWSManagedRulesAmazonIpReputationList",
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesSQLiRuleSet",
  ]
}

variable "waf_log_bucket_arn" {
  description = "Bucket for WAF logs (name starts with aws-waf-logs-)"
  type        = string
}

variable "force_destroy" {
  description = "Delete the static bucket even if it contains objects"
  type        = bool
  default     = false
}
