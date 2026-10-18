variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr" {
  description = "IPv4 CIDR range for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones for the VPC"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR ranges for private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR ranges for public subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway resources"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether private subnets share one NAT gateway"
  type        = bool
  default     = true
}
