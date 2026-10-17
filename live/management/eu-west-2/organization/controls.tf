# Implement custom controls on Prod and Nonprod workload OUs
locals {
  workload_controls = {
    "s3-no-public-write"            = "arn:aws:controlcatalog:::control/9j9nwxj789d82sypnukhyyowy"
    "root-no-access-key"            = "arn:aws:controlcatalog:::control/ezfflnh8xgshxb78grtt5sjc5"
    "rds-snapshot-encrypted"        = "arn:aws:controlcatalog:::control/e79v0zr4za0glvkkaalwgmy78"
    "s3-versioning"                 = "arn:aws:controlcatalog:::control/8z6s5s1vsaxgc2db0ny6pue61"
    "ebs-launch-template-encrypted" = "arn:aws:controlcatalog:::control/dcug5jyd7aj1yu3x1o4uzxr8t"
  }

  control_targets = { for name, ou in aws_organizations_organizational_unit.workloads : name => ou.arn }


  control_assignments = {
    for pair in setproduct(
      keys(local.workload_controls),
      keys(local.control_targets)
    ) :
    "${pair[0]}/${pair[1]}" => {
      control = local.workload_controls[pair[0]]
      target  = local.control_targets[pair[1]]
    }
  }
}

resource "aws_controltower_control" "this" {
  for_each = local.control_assignments

  control_identifier = each.value.control
  target_identifier  = each.value.target
}