output "public_subnets_id" {
  value = module.vpc_staging.public_subnets
}

output "private_subnets_id" {
  value = module.vpc_staging.private_subnets
}

output "vpc_cidr_id" {
  value = module.vpc_staging.vpc_cidr_id
}

output "vpc_id" {
  value = module.vpc_staging.vpc_id
}

output "vpc_cidr" {
  value = module.vpc_staging.vpc_cidr
}

output "public_subnet_ids" {
  value = module.vpc_staging.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc_staging.private_subnets
}

output "database_subnet_ids" {
  value = module.vpc_staging.database_subnets
}

output "security_group_id" {
  value = module.vpc_staging.security_group_id
}
