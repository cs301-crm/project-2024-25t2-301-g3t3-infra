resource "kubernetes_cluster_role" "viewer" {
  metadata {
    name = "viewer"
  }
  rule {
    api_groups = ["*"]
    resources  = ["deployments", "configmap", "pods", "secrets", "services"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "eks_viewer_binding" {
  metadata {
    name = "eks-viewer-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "viewer"
  }

  subject {
    kind      = "Group"
    name      = "eks-viewer"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "eks_admin_binding" {
  metadata {
    name = "eks-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = "eks-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}