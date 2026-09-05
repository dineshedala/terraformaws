# This file contains variable values for Terraform
# The secret_value should be populated from GitHub Secrets during CI/CD execution
# Example in GitHub Actions:
#   terraform apply -var="secret_value=${{ secrets.TEST_SECRET_VALUE }}"

# Uncomment and set the following in your CI/CD pipeline or local environment
# secret_value = "your-secret-value-here"

# AWS Region configuration
aws_region = "us-east-1"
