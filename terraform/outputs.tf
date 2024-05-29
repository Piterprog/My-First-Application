output "public_subnets_id" {
  value = module.vpc_staging.public_subnets[*].id
}

output "private_subnets_id" {
  value = module.vpc_staging.private_subnets[*].id
}

output "vpc_cidr_id" {
  value = module.vpc_staging.vpc_id
}

output "security_group_id" {
  value = module.vpc_staging.security_group_id
}
