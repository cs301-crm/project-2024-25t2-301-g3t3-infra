variable "sftp_user_role_arn" {}
variable "sftp_transaction_bucket_name" {}

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED" # TODO: I think can change to lambda after it's provisioned... need test
  endpoint_type          = "PUBLIC"
  protocols              = ["SFTP"]
}

resource "aws_transfer_user" "sftp_user" {
  server_id      = aws_transfer_server.sftp_server.id
  user_name      = "sftp_user"
  role           = var.sftp_user_role_arn
  home_directory = "/${var.sftp_transaction_bucket_name}"
}