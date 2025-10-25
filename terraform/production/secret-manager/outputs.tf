output "secret_id" {
  description = "The ID of the secret"
  value       = aws_secretsmanager_secret.fast_api_credentials.id
}

output "secret_arn" {
  description = "The ARN of the secret"
  value       = aws_secretsmanager_secret.fast_api_credentials.arn
}

output "secret_name" {
  description = "The name of the secret"
  value       = aws_secretsmanager_secret.fast_api_credentials.name
}

output "secret_version_id" {
  description = "The version ID of the secret"
  value       = aws_secretsmanager_secret_version.fast_api_credentials_version.version_id
}
