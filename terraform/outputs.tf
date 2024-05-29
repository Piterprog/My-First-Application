output "public_subnets_id" {
  value = module.vpc_staging.public_subnets
}

output "private_subnets_id" {
  value = module.vpc_staging.private_subnets
}

output "vpc_cidr_id" {
  value = module.vpc_staging.vpc_id
}

output "security_group_id" {
  value = aws_security_group.my_security_group.id
}
