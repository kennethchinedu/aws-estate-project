variable "name" {
  description = "Prefix for every resource in this stack"
  type        = string
  default     = "payments-dev-pygoat"
}

variable "image_tag" {
  description = "PyGoat image tag in ECR"
  type        = string
}

variable "operator_ip_cidrs" {
  description = "Only sources allowed in (PyGoat is deliberately vulnerable)"
  type        = list(string)
}

variable "enable_cloudfront" {
  description = "Create the CloudFront distribution. Off until the account is verified for CloudFront"
  type        = bool
  default     = false
}

variable "public_alb_for_operator" {
  description = "Test only: internet-facing ALB reachable from operator_ip_cidrs, with no WAF in front"
  type        = bool
  default     = false
}
