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
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.46.3"

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
    name  = "vpcId"
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

resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  version          = "4.12.1"

  values = [file("${path.module}/values/nginx-ingress.yaml")]

  depends_on = [helm_release.aws_lbc]
}

resource "helm_release" "cert_manager" {
  name = "cert-manager"

  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.17.1"

  values = [file("${path.module}/values/cert-manager.yaml")]

  depends_on = [helm_release.nginx_ingress]
}

resource "helm_release" "prometheus-k8s" {
  name = "prometheus-k8s"

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "70.3.0"

  values = [file("${path.module}/values/kube-prometheus-stack.yaml")]

  depends_on = [var.eks_private_nodes]
}

resource "helm_release" "efs_csi_driver" {
  name = "aws-efs-csi-driver"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"
  version    = "3.1.8"

  depends_on = [var.efs_mount_target_zone_a, var.efs_mount_target_zone_b]
}

resource "helm_release" "secrets_csi_driver" {
  name = "secrets-store-csi-driver"

  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.4.8"

  depends_on = [helm_release.efs_csi_driver]
}

resource "helm_release" "secrets_csi_driver_aws_provider" {
  name = "secrets-store-csi-driver-provider-aws"

  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "0.3.11"

  depends_on = [helm_release.secrets_csi_driver]
}