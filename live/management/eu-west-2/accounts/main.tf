# Built in the console, imported 2026-10-15.

data "terraform_remote_state" "organization" {
  backend = "s3"
  config = {
    bucket = "aws-estate-tfstate-763054201886"
    key    = "management/eu-west-2/organization/terraform.tfstate"
    region = "eu-west-2"
  }
}

locals {
  ou_ids = data.terraform_remote_state.organization.outputs.ou_ids

  accounts = {
    log-archive   = { name = "Log Archive", ou = "Security" }
    audit         = { name = "Audit", ou = "Security" }
    payments-prod = { name = "payments-prod", ou = "Prod" }
    payments-dev  = { name = "payments-dev", ou = "Nonprod" }
  }
}

resource "aws_organizations_account" "this" {
  for_each = local.accounts

  name              = each.value.name
  email             = var.account_emails[each.key]
  parent_id         = local.ou_ids[each.value.ou]
  close_on_deletion = false # never close a real account from Terraform

  lifecycle {
    prevent_destroy = true
    # Creation-only settings; AWS can't read them back after an import.
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
