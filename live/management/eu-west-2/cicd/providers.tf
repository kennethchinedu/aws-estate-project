provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      project      = "aws-estate"
      owner        = "ken"
      "managed-by" = "terraform"
      stack        = "cicd"
    }
  }
}
