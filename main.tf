data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_organizations_organization" "this" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "logging_bucket_dns" {
  bucket = var.logging_bucket_dns
}

data "aws_s3_bucket" "logging_bucket_flows" {
  bucket = var.logging_bucket_flows
}
