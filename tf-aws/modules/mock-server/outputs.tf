output "pc_mt_id" {
  description = "VPC peering connection id (monetary transactions)"
  value       = aws_vpc_peering_connection.pc_mt.id
}

output "vpc_mock_server_cidr_block" {
  description = "CIDR block for the mock server VPC"
  value       = aws_vpc.vpc.cidr_block
}