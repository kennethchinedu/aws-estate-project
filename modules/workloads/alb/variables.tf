variable "name" {
  description = "Name for the load balancer, target group and security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the security group and target group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the load balancer (two or more AZs)"
  type        = list(string)
}

variable "internal" {
  description = "Internal (private IPs only) or internet-facing"
  type        = bool
  default     = true
}

variable "ingress_cidrs" {
  description = "Source ranges allowed on port 80, by label"
  type        = map(string)
}

variable "target_security_group_id" {
  description = "Security group of the targets"
  type        = string
}

variable "target_port" {
  description = "Port the targets listen on"
  type        = number
}

variable "health_check_path" {
  description = "Target health check path"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP codes that count as healthy"
  type        = string
  default     = "200"
}

variable "access_logs_bucket" {
  description = "Bucket for access logs"
  type        = string
}

variable "access_logs_prefix" {
  description = "Key prefix for access logs"
  type        = string
}
