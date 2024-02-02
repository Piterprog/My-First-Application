
output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database_subnets[*].id
}

output "security_group_id" {
  value = aws_security_group.Security_vpc.id
}

output "security_group_name" {
  value = aws_security_group.Security_vpc_Musad.name
}
output "egress_rule" {
  value = {
    from_port   = aws_security_group.Security_vpc_Musad.egress[0].from_port
    to_port     = aws_security_group.Security_vpc_Musad.egress[0].to_port
    protocol    = aws_security_group.Security_vpc_Musad.egress[0].protocol
    cidr_blocks = aws_security_group.Security_vpc_Musad.egress[0].cidr_blocks
  }
}
