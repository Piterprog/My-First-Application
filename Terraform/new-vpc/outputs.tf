output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_a_id" {
  value = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public_subnet_b.id
}

output "private_subnet_a_id" {
  value = aws_subnet.private_subnet_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_subnet_b.id
}

output "database_subnet_a_id" {
  value = aws_subnet.database_subnet_a.id
}

output "database_subnet_b_id" {
  value = aws_subnet.database_subnet_b.id
}

output "security_group_id" {
  value = aws_security_group.security_mew_vpc.id
}