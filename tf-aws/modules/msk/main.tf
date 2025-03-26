# Fetch Available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# TODO: change CIDR block to variable
# Create 3 subnets across different AZs for MSK
resource "aws_subnet" "msk_subnets" {
  count             = 3
  vpc_id            = aws_vpc.msk_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "scrooge-bank-msk-subnet-${count.index + 1}"
  }
}

# Security Group for MSK
# TODO: apply stricter SG rules
resource "aws_security_group" "msk_sg" {
  name        = "scrooge-bank-msk-sg"
  description = "security group for scrooge msk cluster"
  vpc_id      = aws_vpc.msk_vpc.id

  # Add ingress and egress rules as needed
#   ingress {
#     from_port   = 9092
#     to_port     = 9092
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.msk_vpc.cidr_block]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
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
    instance_type   = "kafka.m7.large"
    client_subnets  = aws_subnet.msk_subnets[*].id
    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
    security_groups = [aws_security_group.msk_sg.id]
  }

  # TODO: specify that clients require iam role to access msk cluster
  # client_authentication {
  #   sasl {
  #     iam = true
  #   }
  # }

  # Encryption configuration
  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
    encryption_in_transit {
      client_broker = "TLS"
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

# configure msk topics
resource "kafka_topic" "logs" {
  name               = "logs"
  replication_factor = 3
  partitions         = 100

  config = {
    "segment.ms"     = "20000"
    "cleanup.policy" = "compact"
  }
}

resource "kafka_topic" "otps" {
  name               = "otps"
  replication_factor = 3
  partitions         = 100

  config = {
    "segment.ms"     = "20000"
    "cleanup.policy" = "compact"
  }
}

resource "kafka_topic" "notifications" {
  name               = "notifications"
  replication_factor = 3
  partitions         = 100

  config = {
    "segment.ms"     = "20000"
    "cleanup.policy" = "compact"
  }
}