output "eks_cluster_id" {
  value = module.eks_cluster.cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks_cluster.cluster_certificate_authority_data
}

output "eks_workers_1_instance_ids" {
  value = module.eks_workers_1.instance_ids
}

output "eks_workers_2_instance_ids" {
  value = module.eks_workers_2.instance_ids
}

output "eks_node_group_role_arn" {
  value = module.eks_node_group_role.iam_role_arn
}