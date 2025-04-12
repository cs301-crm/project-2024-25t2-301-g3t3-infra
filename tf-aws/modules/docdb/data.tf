data "aws_secretsmanager_secret" "docdb_credentials" {
  name = "docdb-credentials"
}

data "aws_secretsmanager_secret_version" "docdb_credentials" {
  secret_id = data.aws_secretsmanager_secret.docdb_credentials.id
}
