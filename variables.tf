variable "aws_region" {
  description = "Region to deploy to"
  type        = string
  default     = "eu-west-3"
}

variable "prefix" {
  description = "A prefix appended to each resource"
  type        = string
  default     = "devops-challenge"
}

variable "default_tags" {
  description = "Default tags to apply to resources"
  type        = map(string)
  default = {
    app = "devops-challenge"
  }
}

variable "env" {
  description = "Name of the environment"
  type        = string
  default     = "dev"
}

variable "ovh_domain_conf" {
  description = "OVH DNS zone configuration if you want to use a custom domain."
  type = object({
    dns_zone_name = string
    subdomain     = optional(string, "")

  })
  default = {
    dns_zone_name = ""
    subdomain     = ""
  }
}

variable "invalid_cache" {
  description = "Flag indicating if we should invalidate the CloudFront Cache after each deployment of the files to the S3 bucket."
  type        = bool
  default     = false
}
