variable "azs" {
  description = "Availability Zones (AZs) to use. If the list is empty, the module uses all available AZs in the region."
  type        = list(string)

  default = []
}

variable "endpoints" {
  description = "Interface VPC endpoints to create. Each key is an AWS service name, for example ecr.dkr or ssm. The module always creates the S3 and DynamoDB gateway endpoints, so it ignores the s3 and dynamodb keys. If ecr.dkr or ssm is true, the S3 gateway endpoint policy also gives access to the AWS buckets of that service."
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
  description = "Name of the S3 bucket for Route 53 DNS query logs."
  type        = string
}

variable "logging_bucket_flows" {
  description = "Name of the S3 bucket for VPC flow logs."
  type        = string
}

variable "name" {
  description = "The name of the VPC."
  type        = string
}

variable "natgw_per_subnet" {
  description = "If true, the module creates one NAT gateway in each AZ. If false, the module creates one NAT gateway in the first AZ, and all private subnets use it."
  type        = bool

  default = true
}

variable "org_units" {
  description = "Organizational units (OUs) to share the subnets with. Each value contains the ARN and the path of an OU. If the map is empty, the module shares the subnets with the full organization."
  type = map(
    object({
      arn  = string
      path = string
    })
  )
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources that support tags. The map must contain the Environment key."
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
