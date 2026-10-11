mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_organizations_organization" {
    defaults = {
      arn = "arn:aws:organizations::123456789012:organization/o-exampleorg"
      id  = "o-exampleorg"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "ap-southeast-2"
    }
  }
}

variables {
  name                 = "test"
  logging_bucket_dns   = "dns-logs"
  logging_bucket_flows = "flow-logs"

  tags = {
    Environment = "test"
  }
}

run "default_subnet_layout" {
  command = plan

  assert {
    condition     = aws_subnet.private["ap-southeast-2a"].cidr_block == "10.128.0.0/20"
    error_message = "The first private subnet must be the first /20 of the lower half."
  }

  assert {
    condition     = aws_subnet.private["ap-southeast-2c"].cidr_block == "10.128.32.0/20"
    error_message = "The third private subnet must be the third /20 of the lower half."
  }

  assert {
    condition     = aws_subnet.public["ap-southeast-2a"].cidr_block == "10.128.128.0/20"
    error_message = "The first public subnet must be the first /20 of the upper half."
  }

  assert {
    condition     = length(aws_subnet.private) == 3 && length(aws_subnet.public) == 3
    error_message = "The module must create one private and one public subnet in each AZ."
  }
}

run "custom_cidr_and_azs" {
  command = plan

  variables {
    azs             = ["ap-southeast-2b"]
    ipv4_cidr_block = "10.0.0.0/20"
  }

  assert {
    condition     = keys(aws_subnet.private) == ["ap-southeast-2b"]
    error_message = "The module must use only the AZs in var.azs."
  }

  assert {
    condition     = aws_subnet.private["ap-southeast-2b"].cidr_block == "10.0.0.0/24"
    error_message = "A /20 VPC must get /24 subnets."
  }

  assert {
    condition     = aws_subnet.public["ap-southeast-2b"].cidr_block == "10.0.8.0/24"
    error_message = "Public subnets must start at the upper half of the VPC CIDR block."
  }
}

run "nat_gateway_per_az" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "By default, the module must create one NAT gateway in each AZ."
  }

  assert {
    condition     = keys(aws_route.private_nat_gateway) == ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    error_message = "Each private route table must have a default route to a NAT gateway."
  }
}

run "single_nat_gateway" {
  command = plan

  variables {
    natgw_per_subnet = false
  }

  assert {
    condition     = keys(aws_nat_gateway.this) == ["ap-southeast-2a"]
    error_message = "With natgw_per_subnet = false, the module must create one NAT gateway in the first AZ."
  }

  assert {
    condition     = length(aws_route.private_nat_gateway) == 3
    error_message = "All private subnets must still get a default route."
  }
}

run "endpoint_selection" {
  command = plan

  variables {
    endpoints = {
      "dynamodb"   = true
      "ecr.dkr"    = true
      "email-smtp" = true
      "s3"         = true
      "sqs"        = false
      "ssm"        = true
    }
  }

  assert {
    condition     = keys(aws_vpc_endpoint.interface) == ["ecr.dkr", "email-smtp", "ssm"]
    error_message = "Only enabled endpoints, other than s3 and dynamodb, must become interface endpoints."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.interface_endpoint) == 9
    error_message = "Each interface endpoint must get one ingress rule for each private subnet."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.interface_endpoint["email-smtp/ap-southeast-2a"].from_port == 587
    error_message = "The email-smtp endpoint must use port 587."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.interface_endpoint["ssm/ap-southeast-2b"].from_port == 443
    error_message = "Interface endpoints other than email-smtp must use port 443."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.interface_endpoint["ssm/ap-southeast-2b"].cidr_ipv4 == aws_subnet.private["ap-southeast-2b"].cidr_block
    error_message = "Each ingress rule must allow the CIDR block of one private subnet."
  }

  assert {
    condition = toset([for s in data.aws_iam_policy_document.endpoint_gateway_s3.statement : s.sid]) == toset([
      "AccessECRBuckets",
      "AccessSSMBuckets",
      "AllowOrgBuckets",
    ])
    error_message = "The S3 gateway endpoint policy must include the ECR and SSM statements."
  }
}

run "gateway_endpoints_only" {
  command = plan

  assert {
    condition     = length(aws_vpc_endpoint.interface) == 0
    error_message = "By default, the module must not create interface endpoints."
  }

  assert {
    condition     = [for s in data.aws_iam_policy_document.endpoint_gateway_s3.statement : s.sid] == ["AllowOrgBuckets"]
    error_message = "By default, the S3 gateway endpoint policy must allow only organization buckets."
  }
}

run "environment_tag_required" {
  command = plan

  variables {
    tags = {
      Owner = "platform"
    }
  }

  expect_failures = [
    var.tags,
  ]
}
