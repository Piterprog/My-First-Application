provider "aws" {
    region = "us-east-1"
}

variable "vpc_cider" {
    default = "10.0.0.0/16"
}


resource "aws_vpc" "main" {
    cidr_block = var.vpc_cider
    tags = {
      Name = "My VPC"
    }
}