variable "vpc_cidr" {}
variable "az" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# SUBNETS
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "application" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = {
    Name = "application"
  }
}

resource "aws_subnet" "database_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "database_1"
  }
}

resource "aws_subnet" "database_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "database_2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "lb" {
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]
}

# VPC routing table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "application" {
  subnet_id      = aws_subnet.application.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database_1" {
  subnet_id      = aws_subnet.database_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database_2" {
  subnet_id      = aws_subnet.database_2.id
  route_table_id = aws_route_table.private.id
}

# Network ACLs
resource "aws_network_acl" "firewall" {
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl_association" "firewall" {
  network_acl_id = aws_network_acl.firewall.id
  subnet_id      = aws_subnet.public.id
}

# Database NACL
resource "aws_network_acl" "database" {
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl_association" "database_1" {
  network_acl_id = aws_network_acl.database.id
  subnet_id      = aws_subnet.database_1.id
}

resource "aws_network_acl_association" "database_2" {
  network_acl_id = aws_network_acl.database.id
  subnet_id      = aws_subnet.database_2.id
}

# Allow inbound PostgreSQL traffic from public subnet
resource "aws_network_acl_rule" "database_inbound" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "10.0.1.0/24" # Restrict to public subnet
  from_port      = 5432
  to_port        = 5432
}

# Allow all outbound traffic (for response handling)
resource "aws_network_acl_rule" "database_outbound" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = 101
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Security Group
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow access to RDS from Lambda"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_bastion_access" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "10.0.1.0/24" # Public subnet CIDR
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow_lambda_access" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.rds_sg.id
  ip_protocol                  = "-1"
  # cidr_ipv4 = aws_subnet.application.cidr_block
  # ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # allow all outbound
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-security-group"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_rds1" { // send data to clientdb
  security_group_id = aws_security_group.lambda_sg.id
  cidr_ipv4         = aws_subnet.database_1.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_rds2" { // send data to clientdb
  security_group_id = aws_security_group.lambda_sg.id
  cidr_ipv4         = aws_subnet.database_2.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_internet" {
  security_group_id = aws_security_group.lambda_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "lambda_to_rds" {
  security_group_id = aws_security_group.lambda_sg.id
  cidr_ipv4         = aws_subnet.application.cidr_block # CIDR block of the application subnet
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH access to bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
