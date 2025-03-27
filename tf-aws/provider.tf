variable "region" {}

data "aws_eks_cluster" "prod" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "prod" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

provider "helm" {
  kubernetes {
    config_path            = "~/.kube/config"
    host                   = data.aws_eks_cluster.prod.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.prod.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.prod.token
  }
}

provider "kubernetes" {
  config_path            = "~/.kube/config"
  host                   = data.aws_eks_cluster.prod.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.prod.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.prod.token
}

provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.34.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "scrooge-bank-g3t3-terraform-state"
    key    = "global/main.tfstate"
    region = "ap-southeast-1" # cannot use variable because this is used before variables are declared
  }
}