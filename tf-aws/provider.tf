variable "region" {}

# data "aws_eks_cluster" "prod" {
#   name = "prod"
# }
#
# data "aws_eks_cluster_auth" "prod" {
#   name = "prod"
# }
#
# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.prod.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.prod.certificate_authority.0.data)
#     token                  = data.aws_eks_cluster_auth.prod.token
#   }
# }

provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "scrooge-bank-g3t3-terraform-state"
    key    = "global/main.tfstate"
    region = "ap-southeast-1" # cannot use variable because this is used before variables are declared
  }
}