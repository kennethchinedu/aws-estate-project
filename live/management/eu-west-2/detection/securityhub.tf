# Runs in the Management account.
resource "aws_securityhub_organization_admin_account" "this" {
  admin_account_id = "056164769591"
  depends_on = [aws_securityhub_account.audit] # "don't start until SH is ON in Audit"

}

# Enable Security Hub in Audit without default standards
resource "aws_securityhub_account" "audit" {
  provider = aws.audit

  enable_default_standards = false
  
}

# Automatically enable Security Hub for new organization accounts
resource "aws_securityhub_organization_configuration" "this" {
  provider = aws.audit

  auto_enable           = true
  auto_enable_standards = "NONE"

  depends_on = [
    aws_securityhub_organization_admin_account.this,
    aws_securityhub_account.audit
  ]
}

# Subscribe Audit to the CIS AWS Foundations Benchmark
resource "aws_securityhub_standards_subscription" "cis" {
  provider = aws.audit

  standards_arn = "arn:aws:securityhub:eu-west-2::standards/cis-aws-foundations-benchmark/v/3.0.0"

  depends_on = [
    aws_securityhub_account.audit
  ]
}
