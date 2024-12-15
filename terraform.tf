terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }

    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.37"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    # Automatically apply these tags to all the resources
    tags = merge({ "env" : var.env }, var.default_tags)
  }
}

provider "aws" {
  # CloudFront cert needs to be in us-east-1
  alias  = "cloudfront-us-east-1"
  region = "us-east-1"
}

provider "ovh" {
  endpoint = "ovh-eu"
}
