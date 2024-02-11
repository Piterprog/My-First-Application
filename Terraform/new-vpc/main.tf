
provider "aws" {
  region = "us-east-1"
}

 #------------------------------------------------- VPC -----------------------------------------------
resource "aws_vpc" "main" {
  cidr_block          = "10.0.0.0/16"
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    Name = var.environment
  }
}

#----------------------------------------------- Internet Gateway -------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.environment
  }
}

#----------------------------------------------- Table Subnets ----------------------------------------
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name                       = "${var.environment}-Public-A"
    "kubernetes.io/role/elb"  = "1"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name                       = "${var.environment}-Public-B"
    "kubernetes.io/role/elb"  = "1"
  }
}

#--------------------------------------------- Subnets ------------------------------------------------
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name                                 = "${var.environment}-Private-A"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = var.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name                                 = "${var.environment}-Private-B"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

#------------------------------------------------ Database subnets ------------------------------------

resource "aws_subnet" "database_subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-Database-A"
  }
}

resource "aws_subnet" "database_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = var.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-Database-B"
  }
}

#------------------------------------------------ Elastic IPs -----------------------------------------
resource "aws_eip" "nat_gateway_a" {
  domain = "vpc"
  tags = {
    Name = "${var.environment}-MyElastic-A"
  }
}

resource "aws_eip" "nat_gateway_b" {
  domain = "vpc"
  tags = {
    Name = "${var.environment}-MyElastic-B"
  }
}

#-------------------------------------------------- NAT Gateways --------------------------------------

resource "aws_nat_gateway" "nat_gateway_a" {
  allocation_id = aws_eip.nat_gateway_a.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = "${var.environment}-Nat-gateway-A"
  }
}

resource "aws_nat_gateway" "nat_gateway_b" {
  allocation_id = aws_eip.nat_gateway_b.id
  subnet_id     = aws_subnet.public_subnet_b.id
  tags = {
    Name = "${var.environment}-Nat-gateway-B"
  }
}

#------------------------------------------------ Table routs -----------------------------------------

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public_route_table"
    Environment = "Production"  
  }
}

resource "aws_route_table" "private_route_table_a" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private_route_table_A"
    Environment = "Development"  
  }
}

resource "aws_route_table" "private_route_table_b" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private_route_table_B"
    Environment = "Staging"  
  }
}

resource "aws_route_table" "database_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "database_route_table"
    Environment = "Staging"  
  }
}

#------------------------------------ Ассоциация таблиц маршрутизации -----------------------------------------

resource "aws_route_table_association" "public_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_association_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_association_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table_b.id
}

resource "aws_route_table_association" "database_association_a" {
  subnet_id      = aws_subnet.database_subnet_a.id
  route_table_id = aws_route_table.database_route_table.id
}

resource "aws_route_table_association" "database_association_b" {
  subnet_id      = aws_subnet.database_subnet_b.id
  route_table_id = aws_route_table.database_route_table.id
}
#-------------------------------------- Routs NAT gatewaye --------------------------------------------


resource "aws_route" "private_route_a" {
  route_table_id         = aws_route_table.private_route_table_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_a.id
}

resource "aws_route" "private_route_b" {
  route_table_id         = aws_route_table.private_route_table_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_b.id
}
