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

data "terraform_remote_state" "eks-cluster" {
  backend = "s3"
  config = {
    bucket = "vpc-piter-kononihin-terraform"
    key    = "dev/eks/terraform.tfstate"
    region = "us-east-1"
  }
}

#--------------------------------------------------- EKS cluster --------------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": [
        "eks.amazonaws.com",
        "ec2.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "autoscaling.amazonaws.com",
        "cloudformation.amazonaws.com",
        "eks-fargate.amazonaws.com",
        "logs.amazonaws.com",
        "secretsmanager.amazonaws.com",
        "ssm.amazonaws.com",
        "rds.amazonaws.com",
        "kinesis.amazonaws.com",
        "s3.amazonaws.com"
      ] },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "your_cluster_name"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnet_ids 
    security_group_ids =[data.terraform_remote_state.vpc.outputs.security_group_id] 
  }
}

#-------------------------------------------------- Worker Nodes --------------------------------------

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name        = aws_eks_cluster.eks_cluster.name
  node_group_name     = "workers"
  node_role_arn       = aws_iam_role.eks_node_instance_role.arn
  subnet_ids          = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  scaling_config {
    desired_size = 2  
    max_size     = 3  
    min_size     = 1  
  }

  disk_size = 20
  instance_types = ["t2.micro"]
  
  security_group_ids = data.terraform_remote_state.vpc.outputs.security_group_id

  tags = {
  
    Name = "EKS Node Group"
  }

  version = "1.29"

  capacity_type = "SPOT"

  update_config {
    max_unavailable = 1
    max_surge       = 1
  }
}

resource "aws_iam_role" "eks_node_instance_role" {
  name               = "eks-node-instance-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "EKS Node Instance Role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_instance_role_policy" {
  role       = aws_iam_role.eks_node_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}



#-------------------------------------------------- Service Accaunt -----------------------------------

resource "kubernetes_service_account" "my_service_account" {
  metadata {
    name      = "my-service-account"
    namespace = "default"
  }
}

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
    name      = kubernetes_service_account.my_service_account.metadata.0.name
    namespace = kubernetes_service_account.my_service_account.metadata.0.namespace
  }
}
