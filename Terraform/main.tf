# My Terraform
# - VPC
# - Internet Gateway
# - Nat for Private Subnets
# - Public Subnets
# - Private Subnets
# - Database Subnets
# - Security Group

#----------------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
}

#--------------------------------------VPC + IGW -----------------------------------------

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}


#--------------------------------------Public Subnets and Routing -------------------------

resource "aws_subnet" "public_subnets" {
  count                      = length(var.public_subnet_cidrs)
  vpc_id                     = aws_vpc.main.id
  cidr_block                 = element(var.public_subnet_cidrs, count.index)
  availability_zone          = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch    = true
  tags = {
    Name = "${var.env}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "public_subnets" {
    vpc_id         = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
    tags = {
        Name = "${var.env}-route-public-subnets"
    }
}


resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}


#--------------------------------------NAT Gateway with Elastic IPs-----------------------------


resource "aws_eip" "nat" {
    count    = length(var.private_subnet_cidrs)
    domain   = "vpc"
    tags     = {
        Name ="${var.env}-nat-gw-${count.index + 1}"
    }
}


resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id 
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)
  tags = {
    Name = "${var.env}-nat-gw-${count.index + 1}"
  }
}




#------------------------------------Private Subnets and Routing---------------------------------

resource "aws_subnet" "private_subnets" {
    count             = length(var.private_subnet_cidrs)
    vpc_id            = aws_vpc.main.id
    cidr_block        = element(var.private_subnet_cidrs,count.index)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    tags = {
      Name = "${var.env}-private-${count.index + 1}"
      "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_route_table" "private_subnets" {
  count        = length(var.private_subnet_cidrs)
  vpc_id       = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "${var.env}-route-private-subnet-${count.index +1}"
  }
}

resource "aws_route_table_association" "private_routes" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_subnets[count.index].id
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}


#-------------------------------------DataBase Subnet and Routing-----------------------------------

resource "aws_subnet" "database_subnets" {
  count                     = length(var.database_subnet_cidrs)
  vpc_id                    = aws_vpc.main.id
  cidr_block                = element(var.database_subnet_cidrs, count.index)
  availability_zone         = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch   = false
  tags = {
    Name = "${var.env}-database-${count.index + 1}"
  }
}

resource "aws_route_table" "database_subnets" {
    vpc_id         = aws_vpc.main.id
    tags = {
      Name = "${var.env}-route-database-subnets"
    }
}

resource "aws_route_table_association" "database_routes" {
  count          = length(aws_subnet.database_subnets[*].id)
  route_table_id = aws_route_table.database_subnets.id
  subnet_id      = element(aws_subnet.database_subnets[*].id, count.index)
}

#----------------------------------------------Security Group--------------------------------

resource "aws_security_group" "Security_vpc_Musad" {
  name        = "Security_vpc_Musad"
  description = "Security group"
  vpc_id      = aws_vpc.main.id 

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/16"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security group for HTTPS , HTTP"
  }
}


#---------------------------------------------- END -----------------------------------------
