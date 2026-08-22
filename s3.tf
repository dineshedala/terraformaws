# Data source to check if S3 bucket already exists
data "aws_s3_bucket" "existing" {
  bucket = var.bucket_name
}

# S3 Bucket for CSV processing
# Only create if bucket doesn't already exist
resource "aws_s3_bucket" "this" {
  count  = try(data.aws_s3_bucket.existing.id == null ? 1 : 0, 1)
  bucket = var.bucket_name

  tags = {
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

# Get reference to existing bucket if it exists, otherwise use newly created one
locals {
  bucket_id = try(data.aws_s3_bucket.existing.id, aws_s3_bucket.this[0].id)
}

# Good practice defaults - free tier safe (no extra cost)
# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = local.bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning to track object changes
resource "aws_s3_bucket_versioning" "this" {
  bucket = local.bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = local.bucket_id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
