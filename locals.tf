locals {
  # Frontend (Angular) related configuration
  frontend_build_dir   = "frontend/dist/devops-challenge/"
  frontend_config_file = "${path.module}/${local.frontend_build_dir}/assets/config.tpl.json"

  frontend_config_final_content = templatefile(local.frontend_config_file, {
    api_url = aws_apigatewayv2_api.http_api.api_endpoint
    env     = var.env
    }
  )

  # Custom domain related configuration
  ovh_domain_name = var.ovh_domain_conf.dns_zone_name
  cf_subdomain    = var.ovh_domain_conf.subdomain == "" ? "${var.prefix}-${var.env}" : var.ovh_domain_conf.subdomain
  cf_fqdn         = "${local.cf_subdomain}.${local.ovh_domain_name}"
  cf_aliases      = var.ovh_domain_conf.dns_zone_name != "" ? [local.cf_fqdn] : []
  cf_origin_id    = "s3-website-origin-${var.env}"

  # Backend related configuration
  backend_users_raw = jsondecode(file("${path.root}/backend/users.json"))
  # change users list to a map of users suitable for Terraform for_each
  backend_users_map = { for u in local.backend_users_raw : u["id"] => {
    name    = u["name"]
    address = u["address"]
  } }
}