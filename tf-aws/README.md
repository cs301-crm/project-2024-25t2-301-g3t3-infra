# Scrooge Bank Infrastructure
This directory contains the config and tools to setup Scrooge Bank in AWS.

## Structure
- `main.tf`: entry point for the terraform configuration
- `modules/`: contains reusable Terraform modules for AWS services 

## Pre-Deployment Steps:
1. Install Terraform
2. Run `aws configure` to setup your AWS credentials 
3. Run `export AWS_ACCESS_KEY_ID=<your_access_key>`
4. Run `export AWS_SECRET_ACCESS_KEY=<your_secret_key>`
Note: You can get the access key and secret key from IAM -> Users -> <your_username> -> Create access key

## Deployment Steps:
```sh
# Initialize terraform
terraform init
```
```sh
# Plan the deployment
terraform plan
```
```sh
# Apply the deployment
terraform apply
```
```sh
# Destroy the deployment
terraform destroy
```


## TODO:
- [x] Create VPC
- [x] Create firewall subnet, public subnet, application subnet, database subnet
- [x] Create IGW, NAT GW, Elastic IP
- [ ] Configure route table and SG for each subnet
- [x] Create Dynamodb
- [x] ~~Add dynamodb into database subnet~~ -> DynamoDB is fully managed, so actly no need to add it into the subnet oops
- [x] Create RDS instance
- [x] Add RDS instance into database subnet
- [ ] Add replication for dynamodb?
- [ ] Create MSK
- [x] Create SFTP server
- [ ] Create IAM for lambda functions
Snapshot called `has-mock-data` is the RDS instance with mock data