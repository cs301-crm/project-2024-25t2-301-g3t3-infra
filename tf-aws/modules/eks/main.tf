resource "aws_eks_cluster" "prod" {
  name     = "prod"
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = concat(
      var.private_subnet_ids, var.public_subnet_ids
    )
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [var.eks_cluster_role_policy_attachment]
}

resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.prod.name
  node_group_name = "private-nodes"
  node_role_arn   = var.eks_node_role_arn

  subnet_ids = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.xlarge"]

  # eks cluster does not autoscale, this will create aws asgs
  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [var.eks_node_role_policy_attachments]
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.prod.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.5-eksbuild.2"
}