
output "cluster_name" {
  value = aws_eks_cluster.my_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.my_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.my_cluster.certificate_authority.0.data
}

output "worker_group_id" {
  value = aws_eks_node_group.workers.id
}

output "worker_group_arn" {
  value = aws_eks_node_group.workers.arn
}

