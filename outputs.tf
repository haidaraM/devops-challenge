output "frontend_bucket_name" {
  description = "Name of the bucket containing the static files"
  value       = aws_s3_bucket.origin_website.bucket
}

output "cloudfront_url" {
  description = "Cloudfront URL to access the website"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "users_endpoint" {
  description = "API Gateway url to access users"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/users"
}

output "custom_domain" {
  description = "The custom domain name when OVH is used"
  value       = var.ovh_domain_conf.dns_zone_name == "" ? null : "https://${local.cf_fqdn}"
}
