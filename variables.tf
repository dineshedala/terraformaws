variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Base name for the S3 bucket (must be globally unique)"
  type        = string
  default     = "my-terraform-demo-bucket"
}
