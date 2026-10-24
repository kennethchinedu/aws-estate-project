variable "bucket_name" {
  description = "Bucket name. Must start with aws-waf-logs- to receive WAF logs"
  type        = string
}

variable "alb_log_prefix" {
  description = "Key prefix for ALB access logs"
  type        = string
  default     = "alb"
}

variable "expiration_days" {
  description = "Days before log objects expire"
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Delete the bucket even if it contains objects"
  type        = bool
  default     = false
}
