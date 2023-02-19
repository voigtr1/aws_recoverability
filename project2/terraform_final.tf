provider "aws" {
  region = var.aws_region
  shared_credentials_file = "C:\\Users\\q427466\\.aws\\credentials"
  profile = "udacity"
}

terraform {
  backend "local" {}
}
