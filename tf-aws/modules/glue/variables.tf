variable "data_format" {
  description = "Ser format for kafka messages"
  type = string
  default = "PROTOBUF"
}

variable "log_schema_definition" {
  description = "Schema of the kafka log message"
  type = string
  default = "syntax = \"proto3\";\n\npackage com.cs301.crm;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.crm.protobuf\";\n\nmessage Log {\n  string log_id = 1;\n  string actor = 2;\n  string transaction_type = 3;\n  string action = 4;\n  string timestamp = 5;\n}"
}

variable "notification_schema_definition" {
  description = "Schema of the kafka notification message, which is used to notify newly created users"
  type = string
  default = "syntax = \"proto3\";\n\npackage com.cs301.crm;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.crm.protobuf\";\n\nmessage Notification {\n  string email = 1;\n  string username = 2;\n  string tempPassword = 3;\n  string role = 4;\n}"
}

variable "otp_schema_definition" {
  description = "Schema of the kafka otp message"
  type = string
  default = "syntax = \"proto3\";\n\npackage com.cs301.crm;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.crm.protobuf\";\n\nmessage Otp {\n  string email = 1;\n  uint32 otp = 2;\n  string timestamp = 3;\n}"
}