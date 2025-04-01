variable "data_format" {
  description = "Ser format for kafka messages"
  type = string
  default = "PROTOBUF"
}

variable "log_schema_definition" {
  description = "Schema of the kafka log message"
  type = string
  default = "syntax = \"proto3\";\n\npackage com.cs301.shared;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.shared.protobuf\";\n\nmessage Log {\n  string log_id = 1;\n  string actor = 2;\n  string transaction_type = 3;\n  string action = 4;\n  string timestamp = 5;\n}"
}

variable "u2c_schema_definition" {
  description = "Schema of the kafka u2c message, which is used to notify newly created users"
  type = string
  default = "syntax = \"proto3\";\npackage com.cs301.shared;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.shared.protobuf\";\nmessage U2C {\n  string user_email = 1;\n  string username = 2;\n  string temp_password = 3;\n  string user_role = 4;\n}"
}

variable "otp_schema_definition" {
  description = "Schema of the kafka otp message"
  type = string
  default = "syntax = \"proto3\";\n\npackage com.cs301.shared;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.shared.protobuf\";\n\nmessage Otp {\n  string user_email = 1;\n  uint32 otp = 2;\n  string timestamp = 3;\n}"
}

variable "a2c_schema_definition" {
  description = "Schema of the a2c message (agent performed this)"
  type = string
  default = "syntax = \"proto3\";\npackage com.cs301.shared;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.shared.protobuf\";\nmessage A2C {\n  string agent_id = 1;\n  string client_id = 2;\n  string client_email = 3;\n  string crud_type = 4;\n  string account_id = 5;\n  string account_type = 6;\n}"
}

variable "c2c_schema_definition" {
  description = "Schema of the c2c message (before and after)"
  type = string
  default = "syntax = \"proto3\";\npackage com.cs301.shared;\n\noption java_multiple_files = true;\noption java_package = \"com.cs301.shared.protobuf\";\n\nmessage C2C {\n  string agent_id = 1;\n  string client_id = 2;\n  string client_email = 3;\n  string crud_type = 4;\n  CRUDInfo crud_info = 5;\n}\n\nmessage CRUDInfo {\n  string attribute = 1;\n  string before_value = 2;\n  string after_value = 3;\n}"
}
