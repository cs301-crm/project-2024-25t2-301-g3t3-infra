variable "vpc_cidr" {}
variable "az" {}

# VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr

    enable_dns_support = true
    enable_dns_hostnames = true
}

# SUBNETS
resource "aws_subnet" "firewall" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
    availability_zone = var.az
    map_public_ip_on_launch = false
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.az
    map_public_ip_on_launch = true
}

resource "aws_subnet" "application" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.az
  map_public_ip_on_launch = false
}

resource "aws_subnet" "database" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = var.az
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "lb" {
  depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public.id
  depends_on = [ aws_internet_gateway.igw ]
}

# VPC routing table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "application" {
  subnet_id      = aws_subnet.application.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  subnet_id      = aws_subnet.database.id
  route_table_id = aws_route_table.private.id
}

# Network ACLs
resource "aws_network_acl" "firewall" {
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl_association" "firewall" {
  network_acl_id = aws_network_acl.firewall.id
  subnet_id      = aws_subnet.firewall.id
}

# Database NACL
resource "aws_network_acl" "database" {
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl_association" "database" {
  network_acl_id = aws_network_acl.database.id
  subnet_id      = aws_subnet.database.id
}