# - EKS claster
# - Worker nodes 
# - Policys + rols

#------------------------------------ Start Module Terraform ------------------------------------------

resource "aws_eks_cluster" "my_cluster" {
  name                 = "my-cluster"
  role_arn             = aws_iam_role.eks_cluster_role.arn
  version              = "1.29"

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnet_ids   
  }
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "workers"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  disk_size       = 8
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  remote_access {
    ec2_ssh_key = "SSH"
  }
  
  depends_on = [aws_iam_role_policy_attachment.eks_node_policy_attachment]
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
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
  name = "eks-node-role"
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

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ec2_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.eks_cluster_role.name
}

data "aws_iam_policy_document" "eks_cluster_policy" {
  statement {
    actions   = ["eks:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_cluster_policy" {
  name        = "AmazonEKSClusterPolicy"
  description = "Policy for EKS cluster"
  policy      = data.aws_iam_policy_document.eks_cluster_policy.json
}

data "aws_iam_policy_document" "eks_service_policy" {
  statement {
    actions   = ["eks:DescribeCluster", "eks:ListClusters"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_service_policy" {
  name        = "AmazonEKSServicePolicy"
  description = "Policy for EKS service"
  policy      = data.aws_iam_policy_document.eks_service_policy.json
}
