module "payments_dev_vpc" {
  source = "../../../../modules/workloads/vpc"

  name            = var.name
  cidr            = var.cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
}

resource "aws_security_group" "app" {
  name   = "${var.name}-app"
  vpc_id = module.payments_dev_vpc.vpc_id

}

resource "aws_s3_bucket" "payments_data" {
  bucket        = "payments-dev-data-141538081614"
  force_destroy = true

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