terraform {
  backend "s3" {
    bucket       = "aws-estate-tfstate-763054201886"
    key          = "payments-dev/eu-west-2/guardrails/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}