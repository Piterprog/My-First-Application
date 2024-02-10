# - EKS claster
# - Worker nodes 
# - Policys + rols

#------------------------------------------------ EKS cluster -----------------------------------------

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket     = "vpc-piter-kononihin-terraform" 
    key        = "dev/eks/terraform.tfstate"     
    region     = "us-east-1"                     
    encrypt    = true
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "vpc-piter-kononihin-terraform"
    key    = "dev/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

#------------------------------------ Start Module Terraform ------------------------------------------

module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "12.0.0"
  
  cluster_name           = "piterbog"
  cluster_version        = "1.29"
  subnets                = data.terraform_remote_state.vpc.outputs.private_subnet_ids 
  vpc_id                 = data.terraform_remote_state.vpc.outputs.vpc_id
  manage_aws_auth        = true
}

# Рабочая группа 1
module "eks_workers_1" {
  source               = "terraform-aws-modules/eks/aws//modules/workers"
  cluster_name         = module.eks_cluster.cluster_id
  cluster_endpoint     = module.eks_cluster.cluster_endpoint
  cluster_certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
  subnet_ids           = data.terraform_remote_state.vpc.outputs.private_subnet_ids 
  instance_type        = "t2.micro" 
  desired_capacity     = 2
  max_capacity         = 3
  min_capacity         = 1
  key_name             = "SSH" 
}

# Рабочая группа 2
module "eks_workers_2" {
  source               = "terraform-aws-modules/eks/aws//modules/workers"
  cluster_name         = module.eks_cluster.cluster_id
  cluster_endpoint     = module.eks_cluster.cluster_endpoint
  cluster_certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
  subnet_ids           = data.terraform_remote_state.vpc.outputs.private_subnet_ids 
  instance_type        = "t2.micro" 
  desired_capacity     = 2
  max_capacity         = 3
  min_capacity         = 1
  key_name             = "SSH" 
}


module "eks_node_group_role" {
  source                = "terraform-aws-modules/iam/aws//modules/eks_node_group_role"
  create_iam_role       = true
  attach_policy_arns    = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
                           "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
                           "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
}