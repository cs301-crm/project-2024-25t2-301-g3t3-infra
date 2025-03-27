variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
}

variable "eks_openid_connect_issuer_url" {
  description = "OIDC url for EKS to hook"
}