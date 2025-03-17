output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster role"
  value = aws_iam_role.eks.arn
}

output "eks_cluster_role_policy_attachment" {
  description = "Role policy attachment of EKS cluster role"
  value = aws_iam_role_policy_attachment
}