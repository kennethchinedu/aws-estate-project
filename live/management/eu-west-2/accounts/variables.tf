variable "account_emails" {
  description = "Root email per account key. Personal data: set in terraform.tfvars (gitignored)."
  type        = map(string)
}
