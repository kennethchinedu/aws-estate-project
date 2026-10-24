variable "name" {
  description = "Name for the instance, its role, profile and security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the security group"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet for the instance"
  type        = string
}

variable "egress_cidr" {
  description = "Only destination range for outbound traffic (the VPC CIDR)"
  type        = string
}

variable "egress_ports" {
  description = "Outbound TCP ports allowed to egress_cidr"
  type        = list(number)
  default     = [443]
}

variable "egress_prefix_list_ids" {
  description = "Managed prefix lists allowed on 443 (gateway endpoint services)"
  type        = list(string)
  default     = []
}

variable "policy_json" {
  description = "Extra inline IAM policy for the instance role"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_ssm_parameter" {
  description = "SSM parameter holding the AMI ID"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
