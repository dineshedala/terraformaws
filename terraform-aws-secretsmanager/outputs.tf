output "secret_id" {
  description = "The ID of the created secret"
  value       = aws_secretsmanager_secret.test_secret.id
}

output "secret_arn" {
  description = "The ARN of the created secret"
  value       = aws_secretsmanager_secret.test_secret.arn
}

output "secret_name" {
  description = "The name of the created secret"
  value       = aws_secretsmanager_secret.test_secret.name
}

output "secret_version_id" {
  description = "The version ID of the secret version"
  value       = aws_secretsmanager_secret_version.test_secret_version.version_id
}
