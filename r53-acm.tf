resource "aws_acm_certificate" "cf_certificate" {
  count             = var.ovh_domain_conf.dns_zone_name == "" ? 0 : 1
  provider          = aws.cloudfront-us-east-1
  domain_name       = local.cf_fqdn
  validation_method = "DNS"
  tags              = merge({ Name = local.cf_fqdn })

  lifecycle {
    create_before_destroy = true
  }
}

resource "ovh_domain_zone_record" "cf_record" {
  count     = var.ovh_domain_conf.dns_zone_name == "" ? 0 : 1
  fieldtype = "CNAME"
  subdomain = local.cf_subdomain
  target    = "${aws_cloudfront_distribution.website.domain_name}."
  zone      = local.ovh_domain_name
  ttl       = 60
}

resource "ovh_domain_zone_record" "cert_validation_record" {
  count     = var.ovh_domain_conf.dns_zone_name == "" ? 0 : 1
  fieldtype = "CNAME"
  subdomain = replace(tolist(aws_acm_certificate.cf_certificate[0].domain_validation_options)[0].resource_record_name, ".${local.ovh_domain_name}.", "")
  target    = tolist(aws_acm_certificate.cf_certificate[0].domain_validation_options)[0].resource_record_value
  zone      = local.ovh_domain_name
  ttl       = 60
}

resource "aws_acm_certificate_validation" "validation" {
  count                   = var.ovh_domain_conf.dns_zone_name == "" ? 0 : 1
  provider                = aws.cloudfront-us-east-1
  certificate_arn         = aws_acm_certificate.cf_certificate[0].arn
  validation_record_fqdns = ["${ovh_domain_zone_record.cert_validation_record[0].subdomain}.${ovh_domain_zone_record.cert_validation_record[0].zone}"]
}
