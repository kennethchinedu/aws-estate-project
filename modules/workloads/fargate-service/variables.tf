variable "name" {
  description = "Name for the cluster, service, task family, container, roles and security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the security group"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the tasks"
  type        = list(string)
}

variable "image" {
  description = "Container image, with tag"
  type        = string
}

variable "command" {
  description = "Container command; null keeps the image's CMD"
  type        = list(string)
  default     = null
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of tasks"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Plain environment variables"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variables injected from Secrets Manager, as name = valueFrom ARN"
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Secrets the execution role may read"
  type        = list(string)
  default     = []
}

variable "secret_kms_key_arns" {
  description = "KMS keys encrypting those secrets"
  type        = list(string)
  default     = []
}

variable "task_policy_json" {
  description = "Inline IAM policy for the task role; null for none"
  type        = string
  default     = null
}

variable "target_group_arn" {
  description = "Load balancer target group"
  type        = string
}

variable "load_balancer_security_group_id" {
  description = "Load balancer security group, allowed in on container_port"
  type        = string
}

variable "egress_security_groups" {
  description = "Outbound to security groups, by label"
  type = map(object({
    security_group_id = string
    port              = number
  }))
  default = {}
}

variable "egress_prefix_lists" {
  description = "Outbound to managed prefix lists, by label"
  type = map(object({
    prefix_list_id = string
    port           = number
  }))
  default = {}
}

variable "health_check_grace_period" {
  description = "Seconds before load balancer health checks count"
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 7
}
