output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster role"
  value       = aws_iam_role.eks.arn
}

output "eks_cluster_role_policy_attachment" {
  description = "Role policy attachment of EKS cluster role"
  value       = aws_iam_role_policy_attachment.prod-AmazonEKSClusterPolicy
}

output "eks_node_role_arn" {
  description = "ARN of EKS node group"
  value       = aws_iam_role.nodes.arn
}

output "eks_node_role_policy_attachments" {
  description = "Role policy attachment of EKS node role"
  value = [
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy
  ]
}

output "sftp_user_role_arn" {
  value = aws_iam_role.sftp_user_role.arn
}

output "process_monetary_transactions_lambda_role_arn" {
  value = aws_iam_role.process_monetary_transactions_lambda_role.arn
}