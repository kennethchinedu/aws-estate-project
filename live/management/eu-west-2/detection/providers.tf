provider "aws" {
  region = "eu-west-2"


  default_tags {
    tags = {
      project      = "aws-estate"
      owner        = "ken"
      "managed-by" = "terraform"
      stack        = "organization"
    }
  }
}

provider "aws" {
  alias  = "audit"
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::056164769591:role/AWSControlTowerExecution"
    session_name = "terraform-detection"
  }

  default_tags {
    tags = {
      project      = "aws-estate"
      owner        = "ken"
      "managed-by" = "terraform"
      stack        = "organization"
    }
  }
}