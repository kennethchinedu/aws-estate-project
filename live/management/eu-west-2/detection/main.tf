# Assign account as guarduty admin
resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = "056164769591"
}

# Enable guard duty in audit
resource "aws_guardduty_detector" "audit" {
  provider = aws.audit

  enable = true
}

# Enable guard duty across all accounts
resource "aws_guardduty_organization_configuration" "this" {
  provider                         = aws.audit
  auto_enable_organization_members = "ALL"

  detector_id = aws_guardduty_detector.audit.id

  depends_on = [aws_guardduty_organization_admin_account.this]
}