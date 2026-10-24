resource "aws_backup_vault" "this" {
  name          = var.name
  kms_key_arn   = var.kms_key_arn
  force_destroy = var.force_destroy
}

# Governance mode: no changeable_for_days, so the lock can still be removed by privileged principals
resource "aws_backup_vault_lock_configuration" "this" {
  backup_vault_name  = aws_backup_vault.this.name
  min_retention_days = var.min_retention_days
  max_retention_days = var.max_retention_days
}

resource "aws_backup_plan" "this" {
  name = var.name

  rule {
    rule_name         = "scheduled"
    target_vault_name = aws_backup_vault.this.name
    schedule          = var.schedule

    lifecycle {
      delete_after = var.delete_after_days
    }
  }
}

resource "aws_iam_role" "this" {
  name = "${var.name}-backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "this" {
  name         = var.name
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = aws_iam_role.this.arn
  resources    = var.resource_arns
}
