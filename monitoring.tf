resource "aws_sns_topic" "alerting" {
  name         = "${var.prefix}-${var.env}-alerting"
  display_name = "SNS for DevOps challenge alerting"
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.prefix}-${var.env}-backend-api-errors"
  alarm_description   = "Alarm triggered when there some errors on the lambda function"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 10
  period              = 60
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  alarm_actions       = [aws_sns_topic.alerting.arn]
  dimensions = {
    FunctionName = module.lambda_function.lambda_function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttled_requests" {
  alarm_name          = "${var.prefix}-${var.env}-dynamodb-throttled-requests"
  alarm_description   = "Alarm triggered when requests to DynamoDB exceed the provisioned throughput limits"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 1
  period              = 60
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/DynamoDB"
  metric_name         = "ThrottledRequests"
  alarm_actions       = [aws_sns_topic.alerting.arn]
  dimensions = {
    TableName = aws_dynamodb_table.users.name
  }
}