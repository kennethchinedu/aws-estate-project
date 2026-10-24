module "payments_dev_vpc" {
  source = "../../../../modules/workloads/vpc"

  name            = var.name
  cidr            = var.cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  database_subnets = var.database_subnets

  # No NAT: AWS APIs only through endpoints. ECR image layers use the S3 gateway endpoint.
  interface_endpoints = [
    "ecr.api", "ecr.dkr",
    "logs",
    "secretsmanager",
    "ssm", "ssmmessages", "ec2messages",
  ]
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "payments_data" {
  description             = "payments-dev data bucket"
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

resource "aws_s3_bucket" "payments_data" {
  bucket        = "payments-dev-data-141538081614"
  force_destroy = true

}

resource "aws_s3_bucket_server_side_encryption_configuration" "payments_data" {
  bucket = aws_s3_bucket.payments_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.payments_data.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "payments_data" {
  bucket = aws_s3_bucket.payments_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Block s3 actions if not through vpc endpoint
resource "aws_s3_bucket_policy" "payments_data" {
  bucket = aws_s3_bucket.payments_data.id

  depends_on = [aws_s3_bucket_public_access_block.payments_data]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "DenyDataAccessOutsideVPCEndpoint"
        Effect    = "Deny"
        Principal = "*"

        # Not s3:ListBucket: HeadBucket needs it, and Terraform (outside the VPC) would
        # then see the bucket as deleted on every refresh.
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          aws_s3_bucket.payments_data.arn,
          "${aws_s3_bucket.payments_data.arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "aws:SourceVpce" = module.payments_dev_vpc.s3_endpoint_id
          }
        }
      }
    ]
  })
}