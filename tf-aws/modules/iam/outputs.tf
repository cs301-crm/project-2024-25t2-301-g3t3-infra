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

output "process_monetary_transactions_lambda_role_arn" {
  value = aws_iam_role.process_monetary_transactions_lambda_role.arn
}

output "bastion_msk_profile_name" {
  description = "name of iam instance profile for bastion access on msk"
  value = aws_iam_instance_profile.bastion_profile.name
}

output "transfer_logging_role_arn" {
  description = "ARN of the transfer logging role"
  value       = aws_iam_role.transfer_logging_role.arn
}

output "transfer_s3_role_arn" {
  description = "ARN of the transfer S3 role"
  value       = aws_iam_role.transfer_s3_role.arn
}

output "external_server_transfer_role_arn" {
  description = "ARN of the external server transfer role"
  value       = aws_iam_role.external_server_transfer_role.arn
}

