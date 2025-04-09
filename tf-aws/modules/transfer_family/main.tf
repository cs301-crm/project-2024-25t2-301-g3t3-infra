variable "sftp_transaction_bucket_name" {}
variable "transfer_logging_role_arn" {}
variable "transfer_s3_role_arn" {}
variable "vpc_id" {}
variable "private_subnet_ids" {}
variable "tf_sg_id" {}
variable "external_server_transfer_role_arn" {}

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "VPC"
  protocols              = ["SFTP"]
  domain                 = "S3"

  logging_role = var.transfer_logging_role_arn 
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer.arn}:*"
  ]

  workflow_details {
    on_upload {
      execution_role = var.transfer_s3_role_arn
      workflow_id    = aws_transfer_workflow.sftp_workflow.id
    }
  }

  endpoint_details {
    subnet_ids = var.private_subnet_ids 
    security_group_ids = [
      var.tf_sg_id
    ]
    vpc_id = var.vpc_id
  }

  force_destroy = true

  tags = {
    Name = "monetary-transactions"
  }
}


resource "aws_transfer_user" "sftp_user" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = "mock-external-server"
  role      = var.external_server_transfer_role_arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/${aws_s3_bucket.sftp_bucket.bucket}/monetary_transactions" // https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-transfer-user.html
  }
}

resource "aws_cloudwatch_log_group" "transfer" {
  name_prefix = "transfer_mt_"
}

resource "aws_transfer_ssh_key" "example" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user.user_name
  body      = trimspace(file("~/.ssh/cs301-tf.pub"))
}

resource "aws_transfer_workflow" "sftp_workflow" {
  steps {
    copy_step_details {
      name = "copy-to-s3"
      destination_file_location {
        s3_file_location {
          bucket = aws_s3_bucket.sftp_bucket.bucket
          key    = "monetary_transactions/"
        }
      }
      overwrite_existing = "FALSE" # cuz is a bank we don't want overwrite
    }
    type = "COPY"
  }
}

# files received by transfer server will go into this bucket
resource "aws_s3_bucket" "sftp_bucket" {
  bucket = "scrooge-bank-g3t3-monetary-transactions"
}