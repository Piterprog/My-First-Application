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

data "terraform_remote_state" "eks-cluster" {
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
    subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
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

resource "aws_iam_policy" "eks_full_access_policy" {
  name        = "eks-full-access-policy"
  description = "Policy allowing full access and deletion of Amazon EKS resources"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "eks:DeleteCluster",
          "eks:DeleteNodegroup",
          "eks:DeleteFargateProfile",
          "eks:DeleteAddon",
          "eks:DeleteIdentityProviderConfig",
          "eks:DeleteNodegroup",
          "eks:DissociateIdentityProviderConfig",
          "eks:DisassociateFargateProfile",
          "eks:DisassociateIdentityProviderConfig",
          "eks:DisassociateNodegroup",
          "eks:TagResource",
          "eks:UntagResource"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role" "eks_management_role" {
  name               = "eks-management-role"
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

resource "aws_iam_role_policy_attachment" "eks_management_policy_attachment" {
  role       = aws_iam_role.eks_management_role.name
  policy_arn = aws_iam_policy.eks_full_access_policy.arn
}

#------------------------------------------------ Nodes -----------------------------------------------
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

resource "aws_iam_policy" "eks_node_policy" {
  name        = "eks-node-policy"
  description = "Policy for managing Amazon EKS nodes"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates",
          "eks:UpdateNodegroupConfig"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.eks_node_policy.arn
}

resource "aws_iam_role_policy_attachment" "eks_cni_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

<<<<<<< HEAD

  
=======
>>>>>>> 7499f13 (destroy)


