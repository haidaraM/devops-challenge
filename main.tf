terraform {
  required_version = ">= 1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }
}

locals {
  default_tags = merge({ "Env" : var.env }, var.default_tags)
}


provider "aws" {
  region = var.aws_region
  default_tags { # Automatically apply these tags to all the resources
    tags = local.default_tags
  }
}


