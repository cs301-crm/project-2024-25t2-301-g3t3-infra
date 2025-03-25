resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.2"

  values = [file("${path.module}/values/metrics-server.yaml")]

  depends_on = [var.eks_private_nodes]
}

resource "helm_release" "cluster_autoscaler" {
  name = "cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"
  namespace = "kube-system"
  version = "9.46.3"

  values = [file("${path.module}/values/cluster-autoscaler.yaml")]

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks_cluster_name
  }

  depends_on = [helm_release.metrics_server]
}

resource "helm_release" "aws_lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.12.0"

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name = "vpcId"
    value = var.vpc_id
  }

  values = [file("${path.module}/values/aws-lbc.yaml")]

  depends_on = [var.eks_private_nodes]
}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.8.13"

  values = [file("${path.module}/values/argocd.yaml")]

  depends_on = [var.eks_private_nodes]
}

resource "helm_release" "image-updater" {
  name = "image-updater"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true
  version          = "0.12.0"

  values     = [file("${path.module}/values/image-updater.yaml")]
  depends_on = [helm_release.argocd]
}