# AWS Control Tower landing zone (v4.0), home region eu-west-2.
# Adopted from the console-created landing zone via imports.tf (not created by Terraform).
#
# Shared accounts (Security OU):
#   Log Archive 215514708005 - centralised CloudTrail + Config logs
#   Audit       056164769591 - Config aggregator + cross-account audit roles
# Governed regions: eu-west-2 (home) and eu-west-1 (DR).
# Region deny is a Control Tower control on the OUs, managed in the organization stack.
resource "aws_controltower_landing_zone" "this" {
  version = "4.0"

  manifest_json = jsonencode({
    governedRegions = ["eu-west-2", "eu-west-1"]

    accessManagement = {
      enabled = true
    }

    centralizedLogging = {
      accountId = "215514708005"
      enabled   = true
      configurations = {
        loggingBucket = {
          retentionDays = 365
        }
        accessLoggingBucket = {
          retentionDays = 3650
        }
      }
    }

    config = {
      accountId = "056164769591"
      enabled   = true
      configurations = {
        loggingBucket = {
          retentionDays = 365
        }
        accessLoggingBucket = {
          retentionDays = 3650
        }
      }
    }

    securityRoles = {
      accountId = "056164769591"
      enabled   = true
    }

    backup = {
      enabled = false
    }
  })

  remediation_types = ["INHERITANCE_DRIFT"]
}
