provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      project      = "aws-estate"
      owner        = "ken"
      "managed-by" = "terraform"
      stack        = "accounts"
    }
  }

  # Control Tower's own tags on enrolled accounts; Terraform must not remove them.
  ignore_tags {
    key_prefixes = ["aws-controltower:"]
  }
}
