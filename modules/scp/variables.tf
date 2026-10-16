variable "name" {
  type        = string
  description = "Name of the SCP as shown in AWS Organizations."
}

variable "content" {
  type        = string
  description = "JSON policy document defining the SCP rules."
}

variable "description" {
  type        = string
  description = "Description of the SCP and its purpose."
}

variable "organizational_unit_ids" {
  type        = set(string)
  description = "Set of OU IDs to which the SCP will be attached."
}