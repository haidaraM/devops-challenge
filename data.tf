data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Required for cloudfront access logs bucket
data "aws_canonical_user_id" "current" {}

data "aws_cloudfront_log_delivery_canonical_user_id" "awslogsdelivery" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_dynamodb_access" {
  statement {
    sid       = "AllowAccessToDynamoDB"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.users.arn]
  }
}

data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid     = "AllowCloudFrontAccessToBucket"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
      type        = "AWS"
    }

    resources = ["${aws_s3_bucket.website.arn}/*"]
  }

}

data "aws_cloudfront_cache_policy" "cache_optimized" {
  name = "Managed-CachingOptimized"
}

# Package the lambda in a zip file
data "archive_file" "lambda_package" {
  output_path = "${var.lambda_directory}/lambda.zip"
  source_file = "${var.lambda_directory}/main.py"
  type        = "zip"
}
