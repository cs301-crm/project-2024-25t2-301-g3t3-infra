variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
}

variable "sftp_bucket_arn" {}
variable "user_aurora_arn" {}
variable "aurora_kms_key_arn" {}
variable "user_aurora_secret_arn" {}
variable "msk_cluster_arn" {}