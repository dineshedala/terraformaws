resource "aws_secretsmanager_secret" "test_secret" {
  name                    = "test-secret"
  description             = "Test secret creation using Terraform"
  recovery_window_in_days = 7

  tags = {
    Environment = "test"
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "test_secret_version" {
  secret_id     = aws_secretsmanager_secret.test_secret.id
  secret_string = var.secret_value
}
