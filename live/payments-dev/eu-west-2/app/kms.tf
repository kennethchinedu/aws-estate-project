# RDS storage, the RDS master secret and backups. Use is granted through IAM.
resource "aws_kms_key" "app" {
  description             = "${var.name} data at rest"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnableIAMPolicies"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

resource "aws_kms_alias" "app" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.app.key_id
}
