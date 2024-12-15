module "lambda_function" {
  source                                  = "terraform-aws-modules/lambda/aws"
  version                                 = "7.17.0"
  function_name                           = "${var.prefix}-${var.env}-api-backend"
  description                             = "API Backend for the DevOps challenge project"
  handler                                 = "main.handler"
  runtime                                 = "python3.11"
  timeout                                 = 29
  tracing_mode                            = "Active"
  attach_tracing_policy                   = true
  create_current_version_allowed_triggers = false

  source_path = "./backend"

  environment_variables = {
    DYNAMODB_TABLE = aws_dynamodb_table.users.name
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
    }
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name   = "dynamodb-access"
  policy = data.aws_iam_policy_document.lambda_dynamodb_access.json
  role   = module.lambda_function.lambda_role_name
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
  for_each   = local.backend_users_map
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

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id               = aws_apigatewayv2_api.http_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = module.lambda_function.lambda_function_invoke_arn
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
