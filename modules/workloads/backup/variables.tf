variable "name" {
  description = "Name for the vault, plan, selection and role"
  type        = string
}

variable "kms_key_arn" {
  description = "Customer managed key for the vault"
  type        = string
}

variable "resource_arns" {
  description = "Resources to back up"
  type        = list(string)
}

variable "schedule" {
  description = "Backup schedule (cron expression)"
  type        = string
  default     = "cron(0 3 * * ? *)"
}

variable "delete_after_days" {
  description = "Days before a recovery point is deleted; at least min_retention_days"
  type        = number
  default     = 7
}

variable "min_retention_days" {
  description = "Vault Lock: shortest retention allowed"
  type        = number
  default     = 1
}

variable "max_retention_days" {
  description = "Vault Lock: longest retention allowed"
  type        = number
  default     = 35
}

variable "force_destroy" {
  description = "Delete the vault even if it holds recovery points"
  type        = bool
  default     = false
}
