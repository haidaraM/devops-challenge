locals {
  users_raw = jsondecode(file("${path.root}/backend/users.json"))
  # change users list to a map of users suitable for Terraform for_each
  users_map = { for u in local.users_raw : u["id"] => {
    name    = u["name"]
    address = u["address"]
  } }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.prefix}-${var.env}-api-backend"
  description        = "IAM Role for the API Backend"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_policy.json
}


resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name   = "dynamodb-access"
  policy = data.aws_iam_policy_document.lambda_dynamodb_access.json
  role   = aws_iam_role.lambda_role.id
}


resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.id
}

resource "aws_iam_role_policy_attachment" "lambda_xray_access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.lambda_role.id
}


resource "aws_lambda_function" "api_backend" {
  function_name    = "${var.prefix}-${var.env}-api-backend"
  description      = "API Backend for the DevOps challenge project"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler"
  runtime          = "python3.8"
  timeout          = 29
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_package.output_path)

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.users.name
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.api_backend.function_name}"
  retention_in_days = 14
}

resource "aws_dynamodb_table" "users" {
  name           = "${var.prefix}-${var.env}-users"
  billing_mode   = "PROVISIONED"
  hash_key       = "id"
  read_capacity  = 3
  write_capacity = 3

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "users" {
  for_each   = local.users_map
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  range_key  = aws_dynamodb_table.users.range_key

  item = <<ITEM
{
"id": {"S": "${each.key}"},
"name": {"S": "${each.value["name"]}"},
"address": {"S": "${each.value["address"]}"}
}

ITEM
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.prefix}-${var.env}-http-api"
  description   = "A simple HTTP API for the devops challenge"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "HEAD"]
  }
}

resource "aws_lambda_permission" "allow_apigateway_to_invoke_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id               = aws_apigatewayv2_api.http_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.api_backend.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  auto_deploy = true
  name        = "$default"
}

resource "aws_apigatewayv2_route" "users" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /users"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
