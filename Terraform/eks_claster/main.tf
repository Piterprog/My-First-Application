# Определение провайдера AWS
provider "aws" {
    region = "us-east-1"
}

# Определение бэкенда Terraform для сохранения состояния в S3
terraform {                       
  backend "s3" {
    bucket     = "vpc-piter-kononihin-terraform" # Ваш бакет
    key        = "dev/eks/terraform.tfstate"     # Путь к состоянию в вашем бакете
    region     = "us-east-1"                     
    encrypt    = true
  }
}

# Получение данных о VPC из удаленного состояния Terraform
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


# Определение роли IAM для узлов EKS
resource "aws_iam_role" "eks_node_instance_role" {
  name = "eks-node-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Определение политики IAM для узлов EKS
resource "aws_iam_policy" "eks_node_instance_policy" {
  name        = "eks-node-instance-policy"
  description = "Policy for EKS node instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "eks:*"
        Resource = "*"
      }
    ]
  })
}

# Прикрепление политики к роли IAM
resource "aws_iam_role_policy_attachment" "eks_node_instance_attachment" {
  role       = aws_iam_role.eks_node_instance_role.name
  policy_arn = aws_iam_policy.eks_node_instance_policy.arn
}

# Определение кластера EKS
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_node_instance_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    security_group_ids = [data.terraform_remote_state.vpc.outputs.security_group_id] 
  }
}

# Определение группы узлов EKS
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "production-nodes"
  node_role_arn   = aws_iam_role.eks_node_instance_role.arn
  subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  scaling_config {
    desired_size = 2  
    max_size     = 3  
    min_size     = 1  
  }

  instance_types = ["t2.micro"]
  ami_type       = "AL2_x86_64"
}


    
  

  


