output "eks_cluster_name" {
  description = "Name of EKS cluster"
  value       = aws_eks_cluster.prod.name
}

output "eks_private_nodes" {
  description = "Private node groups of our EKS"
  value       = aws_eks_node_group.private-nodes
}

output "eks_cluster_sg_id" {
  description = "Cluster security group of EKS"
  value       = aws_eks_cluster.prod.vpc_config[0].cluster_security_group_id
}
