data "aws_vpc" "selected" {
  tags = {
    Name = "piterbog"
  }
}

data "aws_subnet_ids" "public_subnet_cidrs" {
  vpc_id = "data.aws_vpc.piterbog.id"
  filter {
    name = "tag:Name"
    values = ["public-*"]
  }
}

data "aws_subnet_ids" "private_subnet_cidrs" {
  vpc_id = "data.aws_vpc.piterbog.id"
  filter {
    name = "tag:Name"
    values = ["private-*"]
  }
}