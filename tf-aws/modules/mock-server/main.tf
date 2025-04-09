terraform {
  required_providers {
    klayers = {
      version = "~> 1.0.0"
      source  = "ldcorentin/klayer"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# NETWORKING
resource "aws_vpc" "vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mock-server"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"

  tags = {
    Name = "mock-server-public"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "mock-server-private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "mock-server"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "mock-server"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "lambda_sg" {
  name        = "mock-server-sg"
  description = "Allow Lambda to access S3 and SFTP"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mock-server"
  }
}

resource "aws_vpc_endpoint" "transfer" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.ap-southeast-1.transfer"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_security_group.id]
  private_dns_enabled = true

  tags = {
    Name = "sftp-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-southeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_rt.id
  ]
  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private_rt.id
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

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.ap-southeast-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_security_group.id]
  private_dns_enabled = true

  tags = {
    Name = "secretsmanager-endpoint"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block                = "10.2.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.pc_mt.id
  }

  tags = {
    Name = "private-route-table-mock-server"
  }

  depends_on = [aws_vpc_peering_connection.pc_mt]
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# IAM
resource "aws_iam_role" "lambda_role" {
  name = "mock-server-lambda-s3-to-sftp-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "mock-server-lambda-s3-to-sftp-policy"
  description = "Allow lambda of mock server to access S3 and SFTP and secrets manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.storage_bucket.arn,
          "${aws_s3_bucket.storage_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "scheduler_role" {
  name = "eventbridge-scheduler-invoke-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "scheduler-lambda-invoke-policy"
  description = "Allow EventBridge Scheduler to invoke Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.mock_server.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_lambda_policy_attachment" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

# LAMBDA
data "archive_file" "dummy_zip" {
  type        = "zip"
  source_file = "mock-server.py"
  output_path = "mock-server.zip"
}

resource "aws_lambda_function" "mock_server" {
  filename         = "mock-server.zip"
  function_name    = "mock-server"
  role             = aws_iam_role.lambda_role.arn
  handler          = "mock-server.handler"
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 128
  source_code_hash = data.archive_file.dummy_zip.output_base64sha256

  environment {
    variables = {
      S3_BUCKET_NAME     = aws_s3_bucket.storage_bucket.bucket
      SFTP_USERNAME      = "mock-external-server"
      SFTP_ENDPOINT      = var.crm_sftp_server_endpoint
      SFTP_PKEY_PASSWORD = "cs301-tf" // only to unlock the pkey, but not the private key. It's stored in secrets manager
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  layers = [data.klayers_package_latest_version.paramiko.arn]

  tags = {
    Name = "mock-server"
  }
}

data "klayers_package_latest_version" "paramiko" {
  name           = "paramiko"
  region         = "ap-southeast-1"
  python_version = "3.11"
}

# S3
resource "aws_s3_bucket" "storage_bucket" {
  bucket = "scrooge-bank-g3t3-mock-server"
}

resource "aws_s3_bucket_policy" "allow_lambda_access" {
  bucket = aws_s3_bucket.storage_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_role.arn
        }
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.storage_bucket.arn,
          "${aws_s3_bucket.storage_bucket.arn}/*"
        ]
        # Condition = {
        #     StringEquals = {
        #         "aws:sourceVpce" = aws_vpc_endpoint.s3.id
        #     }
        # }
      }
    ]
  })
}

# EVENTBRIDGE
resource "aws_scheduler_schedule_group" "mock-server" {
  name = "mock-server"
}

resource "aws_scheduler_schedule" "mock-server" {
  name       = "mock-server"
  group_name = "mock-server"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minutes)"

  target {
    arn      = aws_lambda_function.mock_server.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }

  state = "DISABLED"
}

# VPC peering
resource "aws_vpc_peering_connection" "pc_mt" {
  peer_vpc_id = aws_vpc.vpc.id
  vpc_id      = var.crm_vpc_id
  auto_accept = true

  tags = {
    Name = "peering-mt-to-crm"
  }
}

resource "aws_vpc_peering_connection_options" "pc_mt" {
  vpc_peering_connection_id = aws_vpc_peering_connection.pc_mt.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}