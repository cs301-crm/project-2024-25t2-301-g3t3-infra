output "amplify_app_id" {
  value = aws_amplify_app.amplify_app.id
}

output "amplify_app_url" {
  value = aws_amplify_domain_association.domain_association.domain_name
}