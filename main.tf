data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_organizations_organization" "this" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}
