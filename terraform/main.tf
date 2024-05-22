provider "aws" {
  region = "us-uest-1"
}


module "vpc_staging" {
  source              = "./modules/vpc"
  env                 = "staging"
  vpc_cidr            = "10.100.0.0/16"
  public_subnet_cidrs = ["10.100.1.0/24", "10.100.2.0/24"]
  private_subnet_cidrs= ["10.100.10.0/24", "10.100.22.0/24"]
}

