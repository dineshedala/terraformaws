output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.csv_processor.function_name
}
