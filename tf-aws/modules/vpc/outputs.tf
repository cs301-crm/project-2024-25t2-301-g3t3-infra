output "vpc_id" {
  value = aws_vpc.main.id
}

output "database_subnet_ids" {
  value = [aws_subnet.database_1.id, aws_subnet.database_2.id]
}

output "application_subnet_ids" {
  value = [aws_subnet.application.id]
}