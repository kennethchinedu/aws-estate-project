output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "nat_public_ips" {
  description = "Public IP addresses of the NAT gateways"
  value       = module.vpc.nat_public_ips
}

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}