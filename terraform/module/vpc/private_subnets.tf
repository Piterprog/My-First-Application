
resource "aws_subnet" "private_subnets" {
    count             = length(var.private_subnet_cidrs)
    vpc_id            = aws_vpc.main.id
    cidr_block        = element(var.private_subnet_cidrs,count.index)
    availability_zone = data.aws_availability_zones.available.names[count.index]
    tags = {
      Name = "${var.env}-private-${count.index + 1}"
      "kubernetes.io/role/internal-elb" = 1
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
