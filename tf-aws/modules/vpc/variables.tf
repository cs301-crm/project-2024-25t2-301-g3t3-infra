variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pc_mt_id" {
  description = "VPC peering connection id"
}

variable "vpc_mock_server_cidr_block" {
  description = "value for the mock server VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "eks_cluster_sg_id" {
}