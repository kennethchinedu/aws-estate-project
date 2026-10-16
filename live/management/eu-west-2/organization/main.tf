# Built in the console, imported 2026-10-15.

data "aws_organizations_organization" "this" {}

locals {
  root_id = data.aws_organizations_organization.this.roots[0].id

  top_level_ous = toset(["Security", "Sandbox", "Suspended", "Workloads", "Policy-Staging", "Infrastructure"])
  workload_ous  = toset(["Prod", "Nonprod"])

  # AWSControlTowerBaseline: what "Register OU" turns on.
  control_tower_baseline_arn     = "arn:aws:controltower:eu-west-2::baseline/17BSJV3IGJ2QSGA2"
  control_tower_baseline_version = "5.0"

  # Created by the landing zone; OU baselines point at it for Identity Center access.
  identity_center_enabled_baseline_arn = "arn:aws:controltower:eu-west-2:763054201886:enabledbaseline/XAM3WV43PRI6Z3223"

  # Security is registered by the landing zone itself; Sandbox is not registered (DECISIONS.md).
  registered_ous = {
    Workloads = aws_organizations_organizational_unit.top["Workloads"].arn
    Prod      = aws_organizations_organizational_unit.workloads["Prod"].arn
    Nonprod   = aws_organizations_organizational_unit.workloads["Nonprod"].arn
  }
}

resource "aws_organizations_organizational_unit" "top" {
  for_each = local.top_level_ous

  name      = each.key
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workloads" {
  for_each = local.workload_ous

  name      = each.key
  parent_id = aws_organizations_organizational_unit.top["Workloads"].id
}

resource "aws_controltower_baseline" "ou" {
  for_each = local.registered_ous

  baseline_identifier = local.control_tower_baseline_arn
  baseline_version    = local.control_tower_baseline_version
  target_identifier   = each.value

  parameters {
    key   = "IdentityCenterEnabledBaselineArn"
    value = local.identity_center_enabled_baseline_arn
  }
}
