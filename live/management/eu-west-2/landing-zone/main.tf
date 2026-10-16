# Built in the console, imported 2026-10-15. Terraform did not create it.
resource "aws_controltower_landing_zone" "this" {
  version = "4.0"

  manifest_json = jsonencode({
    governedRegions = ["eu-west-1", "eu-west-2"] # AWS's stored order; reordering shows as a change

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
