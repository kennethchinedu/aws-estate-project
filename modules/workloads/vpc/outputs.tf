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

output "s3_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "database_subnet_ids" {
  description = "IDs of the isolated database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "RDS subnet group over the database subnets"
  value       = module.vpc.database_subnet_group_name
}

output "endpoints_security_group_id" {
  description = "Security group on the interface endpoints"
  value       = aws_security_group.endpoints.id
}

output "interface_endpoint_ids" {
  description = "Interface endpoint IDs by service short name"
  value       = { for k, e in aws_vpc_endpoint.interface : k => e.id }
}
