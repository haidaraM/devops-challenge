output "website_url" {
  description = "Cloudfront URL to access the website"
  value       = var.ovh_domain_conf.dns_zone_name == "" ? "https://${aws_cloudfront_distribution.website.domain_name}" : "https://${local.cf_fqdn}"
}

output "users_endpoint" {
  description = "API Gateway url to access users"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/users"
}

