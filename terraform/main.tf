module "vpc_staging" {
  source              = "./modules/vpc"
  env                 = "staging"
  vpc_cidr            = "10.100.0.0/16"
  public_subnet_cidrs = ["10.100.1.0/24", "10.100.2.0/24"]
  private_subnet_cidrs= ["10.100.10.0/24", "10.100.22.0/24"]
}

module "security_group" {
 source                = "./modules/security_group"
 vpc_id                = module.vpc_staging.vpc_id
}


output "public_subnets_id" {
 value = module.vpc_staging.public_subnets[*].ids
}

output "privat_subnets_id" {
 value = module.vpc_staging.private_subnets[*].ids
}

output "vpc_cider_id" {
 value = module.vpc_staging.vpc_cidr_id
}

output "sg_id" {
  value = module.security_group.security_group_id
}
