# Archive Lambda function code into a zip file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

# Data source to check if IAM role already exists
data "aws_iam_role" "existing_lambda_exec" {
  name = "csv-processor-lambda-role"
}

# IAM role for Lambda function
# Only create if role doesn't already exist
resource "aws_iam_role" "lambda_exec" {
  count = try(data.aws_iam_role.existing_lambda_exec.arn == null ? 1 : 0, 1)
  name  = "csv-processor-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Get reference to existing role if it exists, otherwise use newly created one
locals {
  lambda_role_name = try(data.aws_iam_role.existing_lambda_exec.name, aws_iam_role.lambda_exec[0].name)
  lambda_role_arn  = try(data.aws_iam_role.existing_lambda_exec.arn, aws_iam_role.lambda_exec[0].arn)
}

# Attach basic Lambda execution role for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = local.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Scoped S3 permissions - only this bucket, only get/put operations
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda-s3-csv-access"
  role = local.lambda_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = "arn:aws:s3:::${local.bucket_id}/*"
    }]
  })

  # Explicit dependency to ensure S3 bucket is created first
  depends_on = [aws_s3_bucket.this]
}

# Lambda function for CSV processing
resource "aws_lambda_function" "csv_processor" {
  function_name    = "csv-processor"
  role             = local.lambda_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128
}

# Allow S3 bucket to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${local.bucket_id}"
}

# Configure S3 bucket to trigger Lambda on CSV uploads
resource "aws_s3_bucket_notification" "csv_trigger" {
  bucket = local.bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
