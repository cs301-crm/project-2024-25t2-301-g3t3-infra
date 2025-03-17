resource "aws_eks_cluster" "prod" {
  name = "prod"
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [var.eks_cluster_role_policy_attachment]
}