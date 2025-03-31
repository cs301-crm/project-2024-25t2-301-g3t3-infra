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

# ClusterRole for ServiceMonitor access
resource "kubernetes_cluster_role" "prometheus_servicemonitor_full_access" {
  metadata {
    name = "prometheus-servicemonitor-full-access"
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["servicemonitors"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["prometheusrules"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }
}

# ClusterRoleBinding for ServiceMonitor access
resource "kubernetes_cluster_role_binding" "prometheus_servicemonitor_full_access" {
  metadata {
    name = "prometheus-servicemonitor-full-access"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus_servicemonitor_full_access.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "prometheus-k8s-kube-promet-prometheus"
    namespace = "monitoring"
  }
}

# Role for Prometheus in default namespace
resource "kubernetes_role" "prometheus_k8s" {
  metadata {
    name      = "prometheus-k8s"
    namespace = "default"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }
}

# RoleBinding for Prometheus in default namespace
resource "kubernetes_role_binding" "prometheus_k8s" {
  metadata {
    name      = "prometheus-k8s"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.prometheus_k8s.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "prometheus-k8s"
    namespace = "monitoring"
  }
}
