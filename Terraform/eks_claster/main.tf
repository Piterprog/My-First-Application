# - EKS claster
# - Worker nodes 
# - Policys + rols

#------------------------------------------------ EKS cluster -----------------------------------------

provider "aws" {
  region = "us-east-1"  
}

#-------------------------------------- backend save to s3 bucket -------------------------------------
terraform {                       
  backend "s3" {
    bucket     = "vpc-piter-kononihin-terraform" 
    key        = "dev/eks/terraform.tfstate"     
    region     = "us-east-1"                     
    encrypt    = true
  }
}

#-------------------------------------------- pull from s3 bucket -------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "vpc-piter-kononihin-terraform"
    key    = "dev/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "eks-clustet" {
  backend = "s3"
  config = {
    bucket = "vpc-piter-kononihin-terraform"
    key    = "dev/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

#--------------------------------------------- My cluster ---------------------------------------------
resource "aws_eks_cluster" "my_cluster" {
  name     = "my-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version = "1.29"

  vpc_config {
    subnet_ids = [
      for index in range(length(data.terraform_remote_state.vpc.outputs.private_subnet_ids)) :
        data.terraform_remote_state.vpc.outputs.private_subnet_ids[index]
    ]
    security_group_ids = [data.terraform_remote_state.vpc.outputs.security_group_id] 
  }

  tags = {
    Name = "My Cluster App"
  }
}
#--------------------------------------------- Worker Nodes -------------------------------------------
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "workers"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  subnet_ids = [
    for index in range(length(data.terraform_remote_state.vpc.outputs.private_subnet_ids)) :
        data.terraform_remote_state.vpc.outputs.private_subnet_ids[index]
  ]

  disk_size = 20
  instance_types = ["t2.micro"]
  
  tags = {
    Name = "My Worck nodes"
  }
}
#----------------------------------------------- Cluster and Nodes ruls -------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "eks_node_role" {
  name               = "eks-node-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#---------------------------------------- KubeCTL admin --------------------------------------
resource "kubernetes_service_account" "my_service_account" {
  metadata {
    name      = "my-service-account"
    namespace = "default"
  }
}

# Назначение роли
resource "kubernetes_cluster_role_binding" "my_cluster_role_binding" {
  metadata {
    name = "my-cluster-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.my_service_account.metadata[0].name
    namespace = kubernetes_service_account.my_service_account.metadata[0].namespace
  }
}