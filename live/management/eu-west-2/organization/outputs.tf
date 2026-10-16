output "ou_ids" {
  description = "OU name => OU ID, read by the accounts stack."
  value = merge(
    { for name, ou in aws_organizations_organizational_unit.top : name => ou.id },
    { for name, ou in aws_organizations_organizational_unit.workloads : name => ou.id },
  )
}
