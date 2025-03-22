resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow access to RDS from lambda"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH access to bastion host"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group" "lambda" {
  name        = "lambda-sg"
  description = "Allow lambda to function"
  vpc_id      = aws_vpc.vpc.id
}

# Allow bastion, lambda access to RDS
resource "aws_vpc_security_group_ingress_rule" "rds_ingress" {
  for_each                     = toset([aws_security_group.lambda.id, aws_security_group.bastion.id])
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# Only allow SSH into bastion
resource "aws_vpc_security_group_ingress_rule" "bastion_ingress" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_rds_egress" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_internet_egress" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.rds.id
  cidr_ipv4                    = "0.0.0.0/0"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

# Allow all outbound from RDS
resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Allow all outbound from bastion
resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0"
  ip_protocol       = "-1"
}

