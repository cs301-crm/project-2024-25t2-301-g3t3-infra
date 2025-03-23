resource "aws_eks_cluster" "prod" {
  name     = "prod"
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = concat(
      var.private_subnet_ids, var.public_subnet_ids
    )
  }

  access_config {
    authentication_mode = "API"
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
  instance_types = ["m5.large"]

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

resource "helm_release" "aws_lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  namespace = "kube-system"
  version = "1.7.2"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.prod.name
  }

   set {
     name = "serviceAccount.name"
     value = "aws-load-balancer-controller"
   }
  depends_on = [aws_eks_node_group.private-nodes]
}