variable "az" {}
variable "region" {}

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

provider "aws" {
  region = var.region
}

module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
  az       = var.az
}

module "iam" {
  source     = "./modules/iam"
  bucket_arn = module.s3.bucket_arn
}

module "kms" {
  source = "./modules/kms"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  table_name   = "business_transactions_table"
}

module "rds-aurora" {
  source              = "./modules/rds-aurora"
  database_subnet_ids = module.vpc.database_subnet_ids
  aurora_kms_key_id   = module.kms.aurora_kms_key_id
}

module "s3" {
  source = "./modules/s3"
}

module "aws_transfer_family" {
  source             = "./modules/aws_transfer_family"
  sftp_user_role_arn = module.iam.sftp_user_role_arn
  bucket_name        = module.s3.bucket_name
}
