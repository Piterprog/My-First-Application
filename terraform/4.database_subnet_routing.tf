

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
    count          = length(var.database_subnet_cidrs)
    vpc_id         = aws_vpc.main.id
    tags = {
      Name = "${var.env}-route-database-subnets"
    }
}

resource "aws_route_table_association" "database_routes" {
  count          = length(aws_subnet.database_subnets[*].id)
  route_table_id = aws_route_table.database_subnets[count.index].id
  subnet_id      = element(aws_subnet.database_subnets[*].id, count.index)
}


