provider "aws" {
  region = "us-east-1"
}

module "vpc_staging" {
  source              = "./modules/vpc"

  env                 = "staging"
  vpc_cidr            = "10.100.0.0/16"
  public_subnet_cidrs = ["10.100.1.0/24", "10.100.2.0/24"]
  private_subnet_cidrs = ["10.100.10.0/24", "10.100.22.0/24"]
}

data "aws_vpc" "staging" {
  id = module.vpc_staging.vpc_id
}

module "my_security_group" {
  source = "./modules/sg_group"

  sg_name        = "sg group for vpc_staging"
  sg_description = "Security group for my application"
  vpc_id         = data.aws_vpc.staging.id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
 tags = {
    Name   = "staging_sg" 
  }
}

