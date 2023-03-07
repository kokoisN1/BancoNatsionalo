provider "aws" {
  region = "us-east-2" 
}

resource "aws_s3_bucket" "example" {
  bucket = "fbgbl"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_lambda_function" "example" {
  filename         = "function.zip"
  function_name    = "my-function"
  role             = aws_iam_role.example.arn
  handler          = "index.handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("function.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.example.bucket
    }
  }
}

resource "aws_iam_role" "example" {
  name = "my-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.example.name
}

resource "aws_api_gateway_rest_api" "example" {
  name = "my-api"
}

resource "aws_api_gateway_resource" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "my-resource"
}

resource "aws_api_gateway_method" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.example.id
  http_method = "GET"
}

resource "aws_api_gateway_integration" "example" {
  rest_api_id             = aws_api_gateway_rest_api.example.id
  resource_id             = aws_api_gateway_resource.example.id
  http_method             = aws_api_gateway_method.example.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.example.arn}/invocations"
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name  = "dev"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}