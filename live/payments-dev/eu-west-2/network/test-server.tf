data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.eu-west-2.s3"
}

# Private EC2, reached only through Session Manager over the VPC endpoints
module "test_server" {
  source = "../../../../modules/private-workload"

  name         = "payments-dev-test-server"
  vpc_id       = module.payments_dev_vpc.vpc_id
  subnet_id    = module.payments_dev_vpc.private_subnet_ids[0]
  egress_cidr  = var.cidr
  egress_ports = [443, 80] # interface endpoints; the app's internal ALB

  egress_prefix_list_ids = [data.aws_ec2_managed_prefix_list.s3.id]

  # List the bucket and read/write objects
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetObject", "s3:PutObject"]
        Resource = [
          aws_s3_bucket.payments_data.arn,
          "${aws_s3_bucket.payments_data.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource = aws_kms_key.payments_data.arn
      }
    ]
  })
}
