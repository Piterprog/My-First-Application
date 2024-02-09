
terraform {
  backend "s3" {
    bucket     = "vpc-piter-kononihin-terraform"
    key        = "dev/vpc/terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true
  }
}

data "terraform_remote_state" "eks-cluster" {
  backend = "s3"
  config = {
    bucket = "vpc-piter-kononihin-terraform"
    key    = "dev/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

