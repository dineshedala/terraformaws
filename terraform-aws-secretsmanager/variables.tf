variable "secret_value" {
  description = "The secret value to store in AWS Secrets Manager. This should be provided from GitHub Secrets."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.secret_value) > 0
    error_message = "The secret_value must not be empty."
  }
}
