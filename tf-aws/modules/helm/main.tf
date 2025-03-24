# resource "helm_release" "aws_lbc" {
#   name = "aws-load-balancer-controller"
#
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.7.2"
#
#   set {
#     name  = "clusterName"
#     value = var.eks_cluster_name
#   }
#
#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }
#   depends_on = [var.eks_private_nodes]
# }

resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.2"

  values = [file("${path.module}/values/metrics-server.yaml")]

  depends_on = [var.eks_private_nodes]
}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "3.35.4"

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