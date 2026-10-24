data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "aws-estate-tfstate-763054201886"
    key    = "payments-dev/eu-west-2/network/terraform.tfstate"
    region = "eu-west-2"
  }
}

locals {
  network = data.terraform_remote_state.network.outputs
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_subnet" "private" {
  for_each = toset(local.network.private_subnet_ids)
  id       = each.value
}

data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}
