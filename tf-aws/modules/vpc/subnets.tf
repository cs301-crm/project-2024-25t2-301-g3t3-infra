resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1) # 10.0.1.0
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-ap-southeast-1a"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/prod" = "owned"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-ap-southeast-1a"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/prod" = "owned"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 3)
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    "Name"                            = "private-ap-southeast-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/prod"      = "owned"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 4)
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags = {
    "Name"                            = "private-ap-southeast-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/prod"      = "owned"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "scrooge-bank-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}
