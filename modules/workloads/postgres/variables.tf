variable "name" {
  description = "Identifier for the instance and its security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the security group"
  type        = string
}

variable "db_subnet_group_name" {
  description = "DB subnet group over isolated subnets"
  type        = string
}

variable "client_security_group_ids" {
  description = "Security groups allowed to connect, by label"
  type        = map(string)
}

variable "kms_key_arn" {
  description = "Customer managed key for storage and the master secret"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL major or minor version"
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "Instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Storage in GiB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Standby in a second AZ"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Block deletion of the instance"
  type        = bool
  default     = true
}
