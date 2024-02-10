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
  backend      = "s3"
  config       = {
    bucket     = "vpc-piter-kononihin-terraform"
    key        = "dev/vpc/terraform.tfstate"
    region     = "us-east-1"
  }
}

#--------------------------------------------------- EKS cluster --------------------------------------

resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
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
    vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnet_ids 
    security_group_ids = [data.terraform_remote_state.vpc.outputs.security_group_id]
  }
}

resource "aws_iam_policy" "eks_cluster_role" {
  name        = "example-policy"
  description = "Example IAM policy for EC2 network interfaces"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:UnassignPrivateIpAddresses",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DeleteNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:AssignPrivateIpAddresses"
        ],
        "Effect": "Allow",
        "Resource": "*",
        "Sid": "IPV4"
      },
      {
        "Action": "ec2:CreateTags",
        "Effect": "Allow",
        "Resource": "arn:aws:ec2:*:*:network-interface/*",
        "Sid": "CreateTags"
      }
    ]
  })
}
#-------------------------------------------------EKS Nodes -------------------------------------------


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

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name        = aws_eks_cluster.eks_cluster.name
  node_group_name     = "workers"
  node_role_arn       = aws_iam_role.eks_node_instance_role.arn
  subnet_ids          = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  scaling_config {
    desired_size      = 2  
    max_size          = 3  
    min_size          = 1  
  }

  disk_size           = 8
  instance_types      = ["t2.micro"]
}

#-------------------------------------------------- Service Accaunt -----------------------------------

resource "kubernetes_cluster_role" "example_role" {
  metadata {
    name = "example-role"
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["pods", "services", "deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "example_role_binding" {
  metadata {
    name = "example-role-binding"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.example_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = ""  
    name      = "Kube"  
    api_group = "rbac.authorization.k8s.io"
  }
}
