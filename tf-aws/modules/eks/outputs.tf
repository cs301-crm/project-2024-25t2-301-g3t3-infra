output "eks_cluster_name" {
  description = "Name of EKS cluster"
  value       = aws_eks_cluster.prod.name
}

output "eks_private_nodes" {
  description = "Private node groups of our EKS"
  value       = aws_eks_node_group.private-nodes
}