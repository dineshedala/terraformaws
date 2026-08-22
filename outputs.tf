output "bucket_name" {
  value = aws_s3_bucket.this[count.index]
}

output "bucket_arn" {
  value = aws_s3_bucket.this[count.index]
}

output "lambda_function_name" {
  value = aws_lambda_function.csv_processor.function_name
}
