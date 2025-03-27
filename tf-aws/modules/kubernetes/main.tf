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

resource "kubernetes_cluster_role" "prometheus-k8s" {
  metadata {
    name = "prometheus-k8s"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "prometheus-k8s" {
  metadata {
    name = "prometheus-k8s-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "prometheus-k8s"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "prometheus-k8s"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = var.efs_file_system_id
    directoryPerms   = "700"
  }

  mount_options = ["iam"]
}