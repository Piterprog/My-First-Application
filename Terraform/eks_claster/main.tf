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

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": ["eks.amazonaws.com", "ec2.amazonaws.com"]},
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "piterbog-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnet_ids 
    security_group_ids = [data.terraform_remote_state.vpc.outputs.security_group_id]
  }
}

resource "aws_iam_policy" "eks_cluster_policy" {
  name        = "eks-cluster-policy"
  description = "Example IAM policy for EKS cluster"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = aws_iam_policy.eks_cluster_policy.arn
}

resource "aws_iam_role" "eks_node_instance_role" {
  name               = "eks-node-instance-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": ["ec2.amazonaws.com", "eks.amazonaws.com"] },
      "Action": "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "EKS Node Instance Role"
  }
}

resource "aws_eks_node_group" "worker_group_1" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "worker-group-1"
  node_role_arn   = aws_iam_role.eks_node_instance_role.arn
  subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  instance_types  = ["t2.small"]
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
}

resource "aws_eks_node_group" "worker_group_2" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "worker-group-2"
  node_role_arn   = aws_iam_role.eks_node_instance_role.arn
  subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  instance_types  = ["t2.medium"]
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
}
