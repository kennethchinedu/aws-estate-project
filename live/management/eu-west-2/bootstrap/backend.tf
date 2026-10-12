terraform {
  backend "s3" {
    bucket       = "aws-estate-tfstate-763054201886"
    key          = "management/eu-west-2/bootstrap/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
