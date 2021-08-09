locals {
  front_config_file = "${path.module}/${var.front_build_dir}/assets/config.tpl.json"
  front_config_final_content = templatefile(local.front_config_file, {
    api_url = aws_apigatewayv2_api.http_api.api_endpoint
    env     = var.env
    }
  )
  cf_origin_id = "s3-website-origin"
}

# Required for cloudfront access logs bucket
data "aws_canonical_user_id" "current" {}

# Just a random suffix for the bucket to avoid naming conflits
resource "random_string" "bucket_suffix" {
  length    = 5
  special   = false
  lower     = true
  min_lower = 5
}

# The bucket hosting the static files
resource "aws_s3_bucket" "website" {
  bucket        = "${var.prefix}-${random_string.bucket_suffix.result}"
  force_destroy = true
  acl           = "private"
}

# We deploy to the architecture image to S3
resource "aws_s3_bucket_object" "architecture" {
  bucket = aws_s3_bucket.website.bucket
  key    = "assets/architecture.png"
  source = "${path.root}/img/architecture.png"
  etag   = filemd5("${path.root}/img/architecture.png") # Triggers updates when the value changes
}

# The bucket for cloudfront access logs
resource "aws_s3_bucket" "cloudfront_access_logs" {
  bucket        = "${var.prefix}-cloudfront-logs-${random_string.bucket_suffix.result}"
  force_destroy = true

  grant {
    id          = data.aws_canonical_user_id.current.id
    permissions = ["FULL_CONTROL"]
    type        = "CanonicalUser"
  }

  grant {
    # Grant CloudFront logs access to your Amazon S3 Bucket
    # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
    permissions = ["FULL_CONTROL"]
    type        = "CanonicalUser"
  }
}

# As Terraform doesn't support S3 sync. So we are using a null ressource to deploy the static files to S3
resource "null_resource" "deploy_to_s3" {
  triggers = {
    s3_bucket        = aws_s3_bucket.website.bucket
    front_index_file = filebase64sha256("${path.module}/${var.front_build_dir}/index.html")
    config_content   = local.front_config_final_content
  }

  # Generate the template for the frontend
  provisioner "local-exec" {
    command = "echo '${local.front_config_final_content}' > ${path.module}/${var.front_build_dir}/assets/config.json"
  }

  provisioner "local-exec" {
    /*
    We suppose here that the required AWS credentials are exported in the environment variables.
    Otherwise, this command will not work
    */
    command = "aws s3 sync --exclude '${aws_s3_bucket_object.architecture.key}' --exclude 'assets/config.tpl.json' --delete ${var.front_build_dir} s3://${aws_s3_bucket.website.bucket}"
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

resource "aws_s3_bucket_policy" "origin_bucket_policy" {
  bucket = aws_s3_bucket.website.bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin access identity for the website bucket ${aws_s3_bucket.website.bucket}"
}

data "aws_cloudfront_cache_policy" "cache_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  comment             = "cloudfront distribution for devops challenge"
  price_class         = var.cloudfront_price_class
  default_root_object = "index.html"

  # As it's an SPA, we let the SPA handle access to files not found in the bucket
  custom_error_response {
    error_caching_min_ttl = 0 # Do not cache error from origin
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.cf_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.cache_optimized.id
  }

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = local.cf_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Because we don't use a custom domain with certificate
    cloudfront_default_certificate = true
  }

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_access_logs.bucket_domain_name
    include_cookies = false
  }
}
