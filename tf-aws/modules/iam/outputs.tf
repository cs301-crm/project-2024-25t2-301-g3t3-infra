output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster role"
  value = aws_iam_role.eks.arn
}