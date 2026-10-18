provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::141538081614:role/AWSControlTowerExecution"
    session_name = "terraform-network"
  }

  default_tags {
    tags = {

      project      = "aws-estate"
      owner        = "ken"
      "managed-by" = "terraform"
      stack        = "network"
      environment  = "dev"
    }
  }
}