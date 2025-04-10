resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.lambda_sg.id, aws_security_group.db_proxy_sg.id]
    description = "Allow access from lambda and db proxy"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH access to bastion host"
  vpc_id      = aws_vpc.vpc.id
}

# resource "aws_security_group" "lambda" {
#   name        = "lambda-sg"
#   description = "Allow lambda to function"
#   vpc_id      = aws_vpc.vpc.id
# }

# # Allow lambda access to RDS
# resource "aws_vpc_security_group_ingress_rule" "rds_to_lambda_ingress" {
#   security_group_id            = aws_security_group.lambda.id
#   referenced_security_group_id = aws_security_group.rds.id
#   ip_protocol                  = "tcp"
#   from_port                    = 5432
#   to_port                      = 5432
# }

# Allow bastion access to RDS
resource "aws_vpc_security_group_ingress_rule" "rds_to_bastion_ingress" {
  security_group_id            = aws_security_group.bastion.id
  referenced_security_group_id = aws_security_group.rds.id
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

# resource "aws_vpc_security_group_egress_rule" "lambda_to_rds_egress" {
#   security_group_id            = aws_security_group.lambda.id
#   referenced_security_group_id = aws_security_group.rds.id
#   ip_protocol                  = "tcp"
#   from_port                    = 5432
#   to_port                      = 5432
# }

# resource "aws_vpc_security_group_egress_rule" "lambda_to_internet_egress" {
#   security_group_id            = aws_security_group.lambda.id
#   referenced_security_group_id = aws_security_group.rds.id
#   ip_protocol                  = "tcp"
#   from_port                    = 443
#   to_port                      = 443
# }

# Allow all outbound from RDS
# resource "aws_vpc_security_group_egress_rule" "rds_egress" {
#   security_group_id = aws_security_group.rds.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
# }

# Allow all outbound from bastion
resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# For application load balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow access to load balancer"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "lb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group" "tf_sg" {
  name        = "transfer-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Security group for Transfer Family SFTP server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_mock_server_cidr_block]
    description = "Allow SFTP access from mock server"
  }
}

resource "aws_security_group" "db_proxy_sg" {
  name        = "db-proxy-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Security group for DB-proxy"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
    description = "Allow access from lambda"
  }

  egress { # use 0.0.0.0/0 for testing
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow all outbound traffic"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg-good"
  vpc_id      = aws_vpc.vpc.id
  description = "Security group for Lambda function"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc_endpoint_security_group" {
  vpc_id = aws_vpc.vpc.id
  name   = "allow traffic to vpc endpoint"
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = [aws_security_group.lambda_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}