data "aws_organizations_organization" "this" {}

locals {
  account_members = { for account in data.aws_organizations_organization.this.accounts : account.id => account if account.id != "056164769591" }
}

# Add organization accounts as GuardDuty members
resource "aws_guardduty_member" "this" {
  provider = aws.audit
  for_each = local.account_members

  account_id  = each.key
  email       = each.value.email
  detector_id = aws_guardduty_detector.audit.id
  invite      = false

  depends_on = [
    aws_guardduty_detector.management
  ]
  # AWS doesn't return email, and reports invite from the member's status"
  lifecycle {

    ignore_changes = [email, invite]
  }
}

# Add organization accounts as Security Hub members
resource "aws_securityhub_member" "this" {
  provider = aws.audit
  for_each = local.account_members

  account_id = each.key
  invite     = false

  depends_on = [
    aws_securityhub_organization_admin_account.this,
    aws_securityhub_account.management
  ]
}