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

resource "aws_iam_policy" "policy" {
  name        = "policy-s3-access"
  description = "Aa s3 access policy"
  policy      = "${file("policys3bucket.json")}"
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
      },
      {
         "Action": "sts:AssumeRole",
         "Effect": "Allow",
         "Principal": {
           "Service": "ec2.amazonaws.com"
         },
         "Sid": ""
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "example" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.example.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
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


# This setup took alot of digging to find !
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.example.arn}"
  principal     = "apigateway.amazonaws.com"

  #--------------------------------------------------------------------------------
  # Per deployment
  #--------------------------------------------------------------------------------
  # The /*/*  grants access from any method on any resource within the deployment.
  # source_arn = "${aws_api_gateway_deployment.test.execution_arn}/*/*"

  #--------------------------------------------------------------------------------
  # Per API
  #--------------------------------------------------------------------------------
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  depends_on = [
        aws_api_gateway_method.example,
        aws_api_gateway_integration.example
      ]
  stage_name  = "dev"
}

locals {
  object_source = "${path.module}/FileFromS3.txt"
}

resource "aws_s3_object" "file_upload" {
  bucket      = aws_s3_bucket.example.bucket
  key         = "FileFromS3.txt"
  source      = local.object_source
  source_hash = filemd5(local.object_source)
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.example.invoke_url
}