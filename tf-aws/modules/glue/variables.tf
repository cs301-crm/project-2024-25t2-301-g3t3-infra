variable "data_format" {
  description = "Ser format for kafka messages"
  type = string
  default = "PROTOBUF"
}

variable "log_schema_definition" {
  description = "Schema of the kafka log message"
  type = string
  default = "syntax = \"proto3\";\npackage com.cs301.crm;\nmessage Log {\n    string log_id = 1;\n  string actor = 2;\n  string transaction_type = 3;\n   string action = 4;\n   string timestamp = 5;\n}"
}