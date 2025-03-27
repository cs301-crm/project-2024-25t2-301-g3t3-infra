variable "eks_cluster_name" {
  description = "Name of EKS cluster"
}

variable "eks_private_nodes" {
  description = "Private node groups of our EKS"
}

variable "vpc_id" {
  description = "Id of VPC"
}

variable "efs_csi_driver_arn" {
  description = "ARN of CSI driver"
}

variable "efs_mount_targets" {
  description = "List of mount target zones"
}