# AWS Secrets Manager Terraform Module

This Terraform module creates an AWS Secrets Manager secret with the name "test-secret" and a description "Test secret creation using Terraform".

## Overview

This module provisions:
- An AWS Secrets Manager secret resource
- A secret version with the value provided from GitHub Secrets
- Outputs for the secret ID, ARN, and name

## Prerequisites

- Terraform >= 1.0
- AWS Account with appropriate credentials
- GitHub repository with secrets configured

## Usage

### Local Usage

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="secret_value=your-secret-value"

# Apply the configuration
terraform apply -var="secret_value=your-secret-value"
```

### GitHub Actions Usage

Add the following to your GitHub Actions workflow to pass the secret from GitHub Secrets:

```yaml
name: Deploy AWS Secret

on:
  push:
    branches:
      - createsecret

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.0
      
      - name: Initialize Terraform
        run: |
          cd terraform-aws-secretsmanager
          terraform init
      
      - name: Plan Terraform
        run: |
          cd terraform-aws-secretsmanager
          terraform plan -var="secret_value=${{ secrets.TEST_SECRET_VALUE }}" -out=tfplan
      
      - name: Apply Terraform
        run: |
          cd terraform-aws-secretsmanager
          terraform apply -auto-approve tfplan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `secret_value` | The secret value to store in AWS Secrets Manager (from GitHub Secrets) | `string` | Yes |
| `aws_region` | AWS region for the secret | `string` | No |

## Outputs

| Name | Description |
|------|-------------|
| `secret_id` | The ID of the created secret |
| `secret_arn` | The ARN of the created secret |
| `secret_name` | The name of the created secret |
| `secret_version_id` | The version ID of the secret version |

## Files

- `main.tf` - Main Terraform configuration for AWS Secrets Manager
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `provider.tf` - AWS provider configuration
- `terraform.tfvars` - Default variable values
- `README.md` - This file

## Notes

- The secret value should never be committed to the repository. Always use GitHub Secrets for sensitive data.
- The recovery window is set to 7 days for the secret deletion.
- All resources are tagged with Environment and ManagedBy tags for better organization.

## Security Best Practices

1. Store sensitive values in GitHub Secrets, not in code
2. Use IAM roles for AWS authentication in CI/CD pipelines
3. Regularly rotate your secrets
4. Monitor secret access using AWS CloudTrail
5. Use least privilege IAM policies
