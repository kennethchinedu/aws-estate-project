# Look up the latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# IAM role: allow EC2 to assume this role
resource "aws_iam_role" "test_server" {
  name = "payments-dev-test-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

# Allow the instance to communicate with AWS Systems Manager
resource "aws_iam_role_policy_attachment" "test_server_ssm" {
  role       = aws_iam_role.test_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow the instance to list the bucket and read/write objects
resource "aws_iam_role_policy" "test_server_s3" {
  name = "payments-dev-test-server-s3"
  role = aws_iam_role.test_server.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ]

      Resource = [
        aws_s3_bucket.payments_data.arn,
        "${aws_s3_bucket.payments_data.arn}/*"
      ]
    }]
  })
}

# Make the role available to EC2
resource "aws_iam_instance_profile" "test_server" {
  name = "payments-dev-test-server"
  role = aws_iam_role.test_server.name
}

# Permit outbound HTTPS from the app security group
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id

  description = "Allow outbound HTTPS"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

# EC2 
resource "aws_instance" "test_server" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro"

  subnet_id = module.payments_dev_vpc.private_subnet_ids[0]

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.test_server.name

  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "payments-dev-test-server"
  }
}