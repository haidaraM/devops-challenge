locals {
  ovh_domain_name     = "haidara.io"
  frontend_sub_domain = "demo-cloud-facile-${var.env}"
  frontend_fqdn       = "${local.frontend_sub_domain}.${local.ovh_domain_name}"
}


resource "aws_acm_certificate" "cf_certificate" {
  provider          = aws.cloudfront-us-east-1
  domain_name       = local.frontend_fqdn
  validation_method = "DNS"
  tags              = merge({ Name = local.frontend_fqdn })

  lifecycle {
    create_before_destroy = true
  }
}

resource "ovh_domain_zone_record" "cf_record" {
  fieldtype = "CNAME"
  subdomain = local.frontend_sub_domain
  target    = "${aws_cloudfront_distribution.website.domain_name}."
  zone      = local.ovh_domain_name
  ttl       = 60
}

resource "ovh_domain_zone_record" "cert_validation_record" {
  fieldtype = "CNAME"
  subdomain = replace(tolist(aws_acm_certificate.cf_certificate.domain_validation_options)[0].resource_record_name, ".${local.ovh_domain_name}.", "")
  target    = tolist(aws_acm_certificate.cf_certificate.domain_validation_options)[0].resource_record_value
  zone      = local.ovh_domain_name
  ttl       = 60
}

resource "aws_acm_certificate_validation" "validation" {
  provider                = aws.cloudfront-us-east-1
  certificate_arn         = aws_acm_certificate.cf_certificate.arn
  validation_record_fqdns = ["${ovh_domain_zone_record.cert_validation_record.subdomain}.${ovh_domain_zone_record.cert_validation_record.zone}"]
}
