variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
}

variable "sftp_bucket_arn" {}
variable "rds_cluster_arn" {}
variable "aurora_kms_key_arn" {}
variable "rds_cluster_secret_arn" {}
variable "msk_cluster_arn" {}
variable "mt_queue_arn" {}