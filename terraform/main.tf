
module "vpc_staging" {
 source                = "./module/vpc"
 env                   = "staging"
 vpc_cidr              = "10.0.0.0/16"
 public_subnets_cidrs  = ["10.100.1.0/24","10.100.2.0/24"]
 privat_subnets_cidrs  = ["10.100.10.0/24","10.100.22.0/24"]
 availability_zones    = ["us-east1a", "us-east1b"]
}


module "security_group" {
 source                = "./module/security_group"
 vpc_id                = module.vpc_staging.vpc_id
}


output "public_subnets_id" {
 value = module.vpc_staging.public_subnets_ids
}

output "privat_subnets_id" {
 value = module.vpc_staging.privat_subnets_ids
}

output "vpc_cider_id" {
 value = module.vpc_staging.vpc_cider_id
}

output "sg_id" {
  value = module.security_group.security_group_id
}
