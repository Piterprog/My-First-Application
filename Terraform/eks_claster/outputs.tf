
output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority.0.data
}

output "worker_group_1_id" {
  value = aws_eks_node_group.worker_group_1.id
}

output "worker_group_1_arn" {
  value = aws_eks_node_group.worker_group_1.arn
}

output "worker_group_2_id" {
  value = aws_eks_node_group.worker_group_2.id
}

output "worker_group_2_arn" {
  value = aws_eks_node_group.worker_group_2.arn
}
