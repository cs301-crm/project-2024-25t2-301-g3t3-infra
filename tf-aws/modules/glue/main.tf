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

resource "aws_glue_schema" "u2c" {
  schema_name       = "u2c"
  registry_arn      = aws_glue_registry.scrooge-bank-registry.arn
  data_format       = var.data_format
  compatibility     = "BACKWARD"
  schema_definition = var.u2c_schema_definition
}

resource "aws_glue_schema" "a2c" {
  schema_name       = "a2c"
  registry_arn      = aws_glue_registry.scrooge-bank-registry.arn
  data_format       = var.data_format
  compatibility     = "BACKWARD"
  schema_definition = var.a2c_schema_definition
}

resource "aws_glue_schema" "c2c" {
  schema_name       = "c2c"
  registry_arn      = aws_glue_registry.scrooge-bank-registry.arn
  data_format       = var.data_format
  compatibility     = "BACKWARD"
  schema_definition = var.c2c_schema_definition
}