# - EKS claster
# - Worker nodes 
# - Policys + rols

#--------------------------------------------- EKS claster -----------------------------------------

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
    key = "dev/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}


data "aws_vpcs" "existing_name" {
  tags = {
    Name = "piterbog-vpc"
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "piterbog_claster"
  role_arn = aws_iam_role.eks_cluster.arn

   vpc_config {
    subnet_ids = [
      for index in range(length(data.terraform_remote_state.vpc.outputs.private_subnet_ids)) : 
        data.terraform_remote_state.vpc.outputs.private_subnet_ids[index]
    ]
  }
}

resource "aws_launch_configuration" "eks_nodes" {
  name          = "eks-worker-nodes"
  image_id      = "ami-0c7217cdde317cfec"  
  instance_type = "t2.micro"               
  key_name      = "SSH"         


}

resource "aws_autoscaling_group" "eks_nodes" {
  name                 = "eks-worker-nodes"
  min_size             = 1                   
  max_size             = 3                   
  desired_capacity     = 2                   
  launch_configuration = aws_launch_configuration.eks_nodes.id
  vpc_zone_identifier  = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  tags = {
    Name = "eks-worker-node"  # Укажите имя тега
  }
}


#-------------------------------------------------- IAM roles ------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_nodes" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster.name
}


#------------------------------------------------ END --------------------------------------------------