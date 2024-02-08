# - EKS claster
# - Worker nodes 
# - Policys + rols

#--------------------------------------------- Backend + data -----------------------------------------

provider "aws" {
    region = "us-east-1"
}

#--------------------------------------------- save in s3 bucket --------------------------------------         

terraform {                       
  backend "s3" {
    bucket     = "vpc-piter-kononihin-terraform" # My bucket
    key        = "dev/eks/terraform.tfstate"     # MY bucket path
    region     = "us-east-1"                     
    encrypt    = true
  }
}

#-------------------------------------------- pull from s3 bucket ---------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "vpc-piter-kononihin-terraform"
    key = "dev/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}


#----------------------------------------------- AMI rule -----------------------------------------------

data "aws_vpc" "existing_vpc" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_iam_role" "eks_role" {
  name = "eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}


#------------------------------------------- EKS cluster ----------------------------------------------

resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = [
     for index in range(length(data.terraform_remote_state.vpc.outputs.private_subnet_ids)) :
        data.terraform_remote_state.vpc.outputs.private_subnet_ids[index]
        ] 
    security_group_ids = [data.terraform_remote_state.vpc.outputs.security_group_id] 
  }
}

#---------------------------------------------- (Worker Nodes)-----------------------------------------
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "production-nodes"
  node_role_arn   = aws_iam_role.eks_node_instance_role.arn
  subnet_ids      = [
    for index in range(length(data.terraform_remote_state.vpc.outputs.private_subnet_ids)) :
        data.terraform_remote_state.vpc.outputs.private_subnet_ids[index]
  ] 
  scaling_config {
    desired_size = 2  
    max_size     = 3  
    min_size     = 1  
  }
  instance_types = ["t2.micro"]
  ami_type = "AL2_x86_64"
}

