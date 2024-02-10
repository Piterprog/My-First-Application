output "eks_cluster_id" {
  value = aws_eks_cluster.my_cluster.id
}

output "eks_node_group_id" {
  value = aws_eks_node_group.workers.id
}