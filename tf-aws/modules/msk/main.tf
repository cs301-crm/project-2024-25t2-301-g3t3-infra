terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 5.0"
      version = "5.68.0"
    }
    kafka = {
      source = "Mongey/kafka"
    }
  }
}

# Create 3 subnets across different AZs for MSK
resource "aws_subnet" "msk_subnets" {
  count             = 3
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 5 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "scrooge-bank-msk-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "msk_sg" {
  name        = "scrooge-bank-msk-sg"
  description = "security group for scrooge msk cluster"
  vpc_id      = var.vpc_id

  # Add ingress and egress rules as needed
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "kafka plaintext access from bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_kms_key" "kms" {
  description = "kms key for msk"
}

# CloudWatch Log Group for MSK Broker Logs
resource "aws_cloudwatch_log_group" "msk_broker_logs" {
  name              = "/aws/msk/scrooge-bank-cluster"
}

# MSK Cluster Configuration
resource "aws_msk_cluster" "scrooge_bank_cluster" {
  cluster_name           = "scrooge-bank-msk-cluster"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    client_subnets  = aws_subnet.msk_subnets[*].id
    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
    security_groups = [aws_security_group.msk_sg.id]
  }

  # specify that clients require iam role to access msk cluster
  client_authentication {
    sasl {
      iam = true
    }
    unauthenticated = true
  }

  # Encryption configuration
  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
    encryption_in_transit {
      # client_broker = "TLS"
      client_broker = "TLS_PLAINTEXT"
      in_cluster    = true
    }
  }

  # Monitoring configuration
  logging_info {
    broker_logs {
        cloudwatch_logs {
        enabled = true
        log_group = aws_cloudwatch_log_group.msk_broker_logs.name
        }
    }
  }

  tags = {
    Name = "scrooge-bank-msk-cluster"
  }
}