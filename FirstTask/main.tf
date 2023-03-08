provider "aws" {
  region = "${var.region}"
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
}

variable region {}
variable AWS_ACCESS_KEY_ID {}
variable AWS_SECRET_ACCESS_KEY {}


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
  handler          = "myapp.index"
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
    for_each = toset([
        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
        "arn:aws:iam::722738472774:role/my-lambda-role-4-s3-ro"
      ])

    policy_arn = each.value
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
  authorization = "NONE"
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
  depends_on = [
        aws_api_gateway_method.example,
        aws_api_gateway_integration.example
      ]
  stage_name  = "dev"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}
