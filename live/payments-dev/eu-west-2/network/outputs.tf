# Read by the app stack (terraform_remote_state).
output "vpc_id" {
  description = "payments-dev VPC ID"
  value       = module.payments_dev_vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets"
  value       = module.payments_dev_vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnets"
  value       = module.payments_dev_vpc.private_subnet_ids
}

output "database_subnet_group_name" {
  description = "RDS subnet group over the isolated database subnets"
  value       = module.payments_dev_vpc.database_subnet_group_name
}

output "endpoints_security_group_id" {
  description = "Security group on the interface endpoints"
  value       = module.payments_dev_vpc.endpoints_security_group_id
}

output "test_server_instance_id" {
  description = "Test server, for SSM sessions and commands"
  value       = module.test_server.instance_id
}
