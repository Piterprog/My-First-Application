
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket     = "vpc-piter-kononihin-terraform"
    key        = "dev/vpc/terraform.tfstate"
    region     = "us-east-1"
    access_key = var.aws_access.key
    secret_key = var.aws_secret_key
    encrypt    = true
  }
}
