locals {
  default_tags = {
    project      = "aws-estate"
    owner        = "ken"
    "managed-by" = "terraform"
    stack        = "app"
    environment  = "dev"
  }
}

provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::141538081614:role/AWSControlTowerExecution"
    session_name = "terraform-app"
  }

  default_tags {
    tags = local.default_tags
  }
}

# WAF for CloudFront lives in us-east-1
provider "aws" {
  # checkov:skip=CKV2_CUSTOM_4: Needed to deploy and attach WAF
  alias  = "us_east_1"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::141538081614:role/AWSControlTowerExecution"
    session_name = "terraform-app"
  }

  default_tags {
    tags = local.default_tags
  }
}
