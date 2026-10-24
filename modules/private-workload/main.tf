data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

resource "aws_iam_role" "this" {
  name = var.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Session Manager access; no SSH, no inbound rules
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "extra" {
  count = var.policy_json == null ? 0 : 1

  name   = var.name
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Private workload, egress to the VPC and gateway endpoints only"
  vpc_id      = var.vpc_id

  # Replace without detaching: the new group exists before the old one is deleted
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = toset([for p in var.egress_ports : tostring(p)])

  security_group_id = aws_security_group.this.id
  description       = "TCP ${each.value} inside the VPC"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_ipv4         = var.egress_cidr
}

# Gateway endpoints (S3) are reached at the service's public ranges, not inside the VPC CIDR
resource "aws_vpc_security_group_egress_rule" "prefix_lists" {
  for_each = toset(var.egress_prefix_list_ids)

  security_group_id = aws_security_group.this.id
  description       = "HTTPS to ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = each.value
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = var.name
  }
}
