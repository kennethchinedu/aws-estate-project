resource "aws_config_config_rule" "required_owner_tag" {
  name = "required-owner-tag"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "owner"
  })

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
}

resource "aws_config_config_rule" "s3_public_access_prohibited" {
  name = "s3-public-access-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LEVEL_PUBLIC_ACCESS_PROHIBITED"
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3_remediation_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    # only SSM acting for this account can assume the role (confused deputy)
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "s3_public_access_remediation" {
  name               = "s3-public-access-remediation"
  assume_role_policy = data.aws_iam_policy_document.s3_remediation_assume_role.json
}

data "aws_iam_policy_document" "s3_public_access_remediation" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
    ]

    # any bucket: it has to fix buckets made outside Terraform, which can't be named here
    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_role_policy" "s3_public_access_remediation" {
  name   = "s3-public-access-remediation"
  role   = aws_iam_role.s3_public_access_remediation.id
  policy = data.aws_iam_policy_document.s3_public_access_remediation.json
}

resource "aws_config_remediation_configuration" "s3_public_access" {
  config_rule_name = aws_config_config_rule.s3_public_access_prohibited.name
  resource_type    = "AWS::S3::Bucket"

  target_type = "SSM_DOCUMENT"
  target_id   = "AWSConfigRemediation-ConfigureS3BucketPublicAccessBlock"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.s3_public_access_remediation.arn
  }

  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = true
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 60
}