# The bucket hosting the static files
resource "aws_s3_bucket" "origin_website" {
  bucket        = "${var.prefix}-${var.env}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# We deploy to the architecture image to S3
resource "aws_s3_object" "architecture_img" {
  bucket = aws_s3_bucket.origin_website.bucket
  key    = "assets/architecture.png"
  source = "${path.root}/img/architecture.png"
  etag   = filemd5("${path.root}/img/architecture.png") # Triggers updates when the value changes
}


# The bucket for CloudFront access logs
resource "aws_s3_bucket" "cf_access_logs" {
  bucket        = "${var.prefix}-${var.env}-cloudfront-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "cf_access_logs" {
  bucket = aws_s3_bucket.cf_access_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cf_logs_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.cf_access_logs]
  bucket     = aws_s3_bucket.cf_access_logs.bucket

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }

    grant {
      permission = "FULL_CONTROL"
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
    }

    grant {
      permission = "FULL_CONTROL"
      grantee {
        # Grant CloudFront logs access to your Amazon S3 Bucket
        # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.awslogsdelivery.id
        type = "CanonicalUser"
      }
    }
  }
}


resource "aws_s3_bucket_policy" "cf_origin_bucket_policy" {
  bucket = aws_s3_bucket.origin_website.bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin access identity for the website bucket ${aws_s3_bucket.origin_website.bucket}"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  comment             = "cloudfront distribution for devops challenge"
  price_class         = "PriceClass_100" # North America, Europe and Israel.
  default_root_object = "index.html"
  aliases             = local.cf_aliases

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
    domain_name = aws_s3_bucket.origin_website.bucket_regional_domain_name
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
    cloudfront_default_certificate = var.ovh_domain_conf.dns_zone_name == ""
    acm_certificate_arn            = var.ovh_domain_conf.dns_zone_name == "" ? null : aws_acm_certificate.cf_certificate[0].arn
    minimum_protocol_version       = var.ovh_domain_conf.dns_zone_name == "" ? "TLSv1" : "TLSv1.2_2021"
    ssl_support_method             = var.ovh_domain_conf.dns_zone_name == "" ? null : "sni-only"
  }

  logging_config {
    bucket          = aws_s3_bucket.cf_access_logs.bucket_domain_name
    include_cookies = false
  }
}

# As Terraform doesn't support S3 sync. So we are using a local provisioner to deploy the static files to S3
resource "terraform_data" "deploy_to_s3" {
  triggers_replace = [
    aws_s3_bucket.origin_website.bucket,
    filebase64sha256("${path.module}/${local.frontend_build_dir}/index.html"),
    local.frontend_config_final_content
  ]

  # Generate the template for the frontend
  provisioner "local-exec" {
    command = "echo '${local.frontend_config_final_content}' > ${path.module}/${local.frontend_build_dir}/assets/config.json"
  }

  /*
    We suppose here that the required AWS credentials are exported in the environment variables.
    Otherwise, the following AWS commands will not work.
  */
  provisioner "local-exec" {
    command = "aws s3 sync --exclude '${aws_s3_object.architecture_img.key}' --exclude 'assets/config.tpl.json' --delete ${local.frontend_build_dir} s3://${aws_s3_bucket.origin_website.bucket}"
  }

  # Do not cache the index.html so that changes are deployed automatically. Other files are cached by default.
  provisioner "local-exec" {
    command = "aws s3 cp --copy-props metadata-directive --cache-control 'max-age=0,no-store' s3://${aws_s3_bucket.origin_website.bucket}/index.html s3://${aws_s3_bucket.origin_website.bucket}/index.html"
  }
}

resource "terraform_data" "invalidate_cache" {
  count = var.invalid_cache ? 1 : 0
  triggers_replace = [
    terraform_data.deploy_to_s3.id
  ]

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths '/*'"
  }
}
