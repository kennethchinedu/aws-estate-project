data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"

  route_table_ids = module.vpc.private_route_table_ids
}