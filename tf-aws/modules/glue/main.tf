resource "aws_glue_registry" "scrooge-bank-registry" {
  registry_name = "scrooge-bank-registry"
}

resource "aws_glue_schema" "logs" {
  schema_name       = "logs"
  registry_arn      = aws_glue_registry.scrooge-bank-registry.arn
  data_format       = var.data_format
  compatibility     = "BACKWARD"
  schema_definition = var.log_schema_definition
}

resource "aws_glue_schema" "otps" {
  schema_name       = "otps"
  registry_arn      = aws_glue_registry.scrooge-bank-registry.arn
  data_format       = var.data_format
  compatibility     = "BACKWARD"
  schema_definition = var.otp_schema_definition
}

resource "aws_glue_schema" "notifications" {
  schema_name       = "notifications"
  registry_arn      = aws_glue_registry.scrooge-bank-registry.arn
  data_format       = var.data_format
  compatibility     = "BACKWARD"
  schema_definition = var.notification_schema_definition
}
