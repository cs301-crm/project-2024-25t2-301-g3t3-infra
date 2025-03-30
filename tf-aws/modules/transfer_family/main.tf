variable "sftp_transaction_bucket_name" {}
variable "transfer_logging_role" {}
variable "transfer_s3_role" {}

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED" # TODO: I think can change to lambda after it's provisioned... need test
  endpoint_type          = "PUBLIC"
  protocols              = ["SFTP"]
  domain = "S3"

  logging_role = var.transfer_logging_role
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer.arn}:*"
  ]

  workflow_details {
    on_upload {
      execution_role = var.transfer_s3_role
      workflow_id = aws_transfer_workflow.sftp_workflow.id
    }
  }

  tags = {
    Name = "monetary-transactions"
  }
}

# resource "aws_transfer_user" "sftp_user" {
#   server_id      = aws_transfer_server.sftp_server.id
#   user_name      = "sftp_user"
#   role           = var.sftp_user_role_arn
#   home_directory = "/${var.sftp_transaction_bucket_name}/monetary_transactions"
# }

resource "aws_transfer_workflow" "sftp_workflow" {
  steps {
    copy_step_details {
      name = "copy-to-s3"
      destination_file_location {
        s3_file_location {
          bucket = var.sftp_transaction_bucket_name
          key = "monetary_transactions/"
        }
      } 
      overwrite_existing = "FALSE" # cuz is a bank we want to keep the real shi
    }
    type = "COPY"
  }
}

resource "aws_cloudwatch_log_group" "transfer" {
    name_prefix = "transfer_mt_"
}

