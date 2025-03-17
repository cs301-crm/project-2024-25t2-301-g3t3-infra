module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  table_name   = "business_transactions_table"
}

module "iam" {
  source = "./modules/iam"
}