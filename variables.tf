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

variable "front_build_dir" {
  description = "The folder where the frontend has been built"
  type        = string
  default     = "frontend/dist/devops-challenge/"
}

variable "lambda_directory" {
  description = "The directory containing lambda"
  type        = string
  default     = "backend"
}

variable "env" {
  description = "Name of the environment"
  type        = string
  default     = "dev"
}

variable "cloudfront_price_class" {
  type        = string
  description = "The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100. See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html"
  default     = "PriceClass_100" # North America, Europe and Israel.
}
