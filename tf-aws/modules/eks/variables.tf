variable "eks_cluster_role_arn" {
  description = "ARN of EKS cluster role"
  type = string
}

variable "subnet_ids" {
  description = "List of all subnets in the VPC"
  type = list(string)
}

variable "eks_cluster_role_policy_attachment" {
  description = "Role policy attachment of eks role"
}