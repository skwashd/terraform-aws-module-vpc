variable "azs" {
  description = "List of AWS Availability Zones to use for deploying resources. If empty all AZs in region used."
  type        = list(any)

  default = []
}

variable "endpoints" {
  description = "VPC PrivateLink endpoints to enable."
  type        = map(bool)

  default = {}
}

variable "ipv4_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string

  default = "10.128.0.0/16"

  validation {
    error_message = "CIDR block must be a valid IPv4 CIDR."
    condition     = can(cidrsubnet(var.ipv4_cidr_block, 0, 0))
  }
}

variable "logging_bucket_dns" {
  description = "Name of the S3 bucket to use for logging DNS requests."
  type        = string
}

variable "logging_bucket_flows" {
  description = "Name of the S3 bucket to use for logging VPC flows."
  type        = string
}

variable "name" {
  description = "The name of the VPC."
  type        = string
}

variable "org_id" {
  description = "ID of the AWS Organisation for this account."
  type        = string

  validation {
    error_message = "Invalid Organisation ID."
    condition     = substr(var.org_id, 0, 2) == "o-"
  }
}

variable "org_units" {
  description = "List of OUs ARNs that can access the VPC. If empty access is limited to the Organization."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to add resources provisioned."
  type        = map(string)

  default = {}

  validation {
    error_message = "Must contain at least one tag."
    condition     = length(keys(var.tags)) > 0
  }

  validation {
    error_message = "Environment tag must be set."
    condition     = contains(keys(var.tags), "Environment")
  }
}

locals {
  azs = length(var.azs) == 0 ? data.aws_availability_zones.available.names : var.azs

  shared_principals = toset(length(var.org_units) > 0 ? var.org_units : [data.aws_organizations_organization.this.arn])
}
