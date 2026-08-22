output "bucket_name" {
  value = var.bucket_name
}

output "bucket_arn" {
  value = "arn:aws:s3:::${var.bucket_name}"
}

output "lambda_function_name" {
  value = aws_lambda_function.csv_processor.function_name
}
