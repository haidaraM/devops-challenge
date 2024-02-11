terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
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

provider "aws" {
  region = var.aws_region

  default_tags { # Automatically apply these tags to all the resources
    tags = merge({ "env" : var.env }, var.default_tags)
  }
}


