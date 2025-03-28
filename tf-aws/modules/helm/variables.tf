variable "eks_cluster_name" {
  description = "Name of EKS cluster"
}

variable "eks_private_nodes" {
  description = "Private node groups of our EKS"
}

variable "vpc_id" {
  description = "Id of VPC"
}

variable "efs_mount_target_zone_a" {
  description = "Mount target zone a"
}

variable "efs_mount_target_zone_b" {
  description = "Mount target zone a"
}