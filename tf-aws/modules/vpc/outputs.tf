output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.db_subnet_group.name
}

output "public_route_table_id" {
  description = "ID of public route table"
  value       = aws_route_table.public_route_table.id
}

output "private_route_table_id" {
  description = "ID of private route table"
  value       = aws_route_table.private_route_table.id
}

output "azs" {
  description = "List of availability zones"
  value       = [aws_subnet.public_subnet_1.availability_zone, aws_subnet.public_subnet_2.availability_zone]
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}
