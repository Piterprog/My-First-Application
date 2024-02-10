
terraform {
  backend "s3" {
    bucket     = "vpc-piter-kononihin-terraform"
    key        = "dev/vpc/terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true
  }
}



