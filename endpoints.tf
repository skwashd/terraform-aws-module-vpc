locals {
  interface_endpoints = toset([for k, v in var.endpoints : k if k != "s3" && k != "dynamodb" && v == true])

  vpc_endpoints_interface = {
    for service, endpoint in aws_vpc_endpoint.interface : service => {
      id                = endpoint.id,
      security_group_id = aws_security_group.interface_endpoint[service].id
    }
  }
  vpc_endpoints_gateway = merge(
    lookup(var.endpoints, "s3", false) ? { "s3" : { id = aws_vpc_endpoint.gateway_s3[0].id, prefix_list = aws_vpc_endpoint.gateway_s3[0].prefix_list_id } } : {},
    lookup(var.endpoints, "dynamodb", false) ? { "dynamodb" : { id = aws_vpc_endpoint.gateway_dynamodb[0].id, prefix_list = aws_vpc_endpoint.gateway_dynamodb[0].prefix_list_id } } : {},
  )
}

resource "aws_vpc_endpoint" "gateway_dynamodb" {
  count = lookup(var.endpoints, "dynamodb", false) ? 1 : 0

  vpc_id          = aws_vpc.this.id
  policy          = data.aws_iam_policy_document.endpoint_gateway_dynamodb[0].json
  service_name    = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  route_table_ids = aws_route_table.private[*].id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-dynamodb"
    },
  )
}

data "aws_iam_policy_document" "endpoint_gateway_dynamodb" {
  count = lookup(var.endpoints, "dynamodb", false) ? 1 : 0

  dynamic "statement" {
    # Using org config, so allow access to all tables in the org
    for_each = var.org_id != "" ? [1] : []
    content {
      sid       = "AllowOrgTables"
      effect    = "Allow"
      resources = ["*"]
      actions   = ["*"]

      condition {
        test     = length(var.org_units) > 0 ? "ForAnyValue:StringEquals" : "StringEquals"
        variable = length(var.org_units) > 0 ? "aws:ResourceOrgPaths" : "aws:ResourceOrgID"
        values   = local.org_paths
      }

      condition {
        test     = length(var.org_units) > 0 ? "ForAnyValue:StringEquals" : "StringEquals"
        variable = length(var.org_units) > 0 ? "aws:PrincipalOrgPaths" : "aws:PrincipalOrgID"
        values   = local.org_paths
      }

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }

  dynamic "statement" {
    # Using account config, so only allow access to all tables in the account
    for_each = var.org_id == "" ? [1] : []
    content {
      sid    = "AllowAccountTables"
      effect = "Allow"
      resources = [
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
      ]
      actions = ["*"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalAccount"
        values = [
          data.aws_caller_identity.current.account_id
        ]
      }
    }
  }
}

resource "aws_vpc_endpoint" "gateway_s3" {
  count = lookup(var.endpoints, "s3", false) ? 1 : 0

  vpc_id       = aws_vpc.this.id
  policy       = data.aws_iam_policy_document.endpoint_gateway_s3[0].json
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = [
    for table in aws_route_table.private : table.id
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-s3"
    },
  )
}

data "aws_iam_policy_document" "endpoint_gateway_s3" {
  count = lookup(var.endpoints, "s3", false) ? 1 : 0

  dynamic "statement" {
    # Using org config, so allow access to all buckets in the org
    for_each = var.org_id != "" ? [1] : []
    content {
      sid       = "AllowOrgBuckets"
      effect    = "Allow"
      resources = ["*"]
      actions   = ["*"]

      condition {
        test     = length(var.org_units) > 0 ? "ForAnyValue:StringEquals" : "StringEquals"
        variable = length(var.org_units) > 0 ? "aws:ResourceOrgPaths" : "aws:ResourceOrgID"
        values   = local.org_paths
      }

      condition {
        test     = length(var.org_units) > 0 ? "ForAnyValue:StringEquals" : "StringEquals"
        variable = length(var.org_units) > 0 ? "aws:PrincipalOrgPaths" : "aws:PrincipalOrgID"
        values   = local.org_paths
      }

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }

  dynamic "statement" {
    # Using account config, so only allow access to all buckets in the account
    for_each = var.org_id == "" ? [1] : []
    content {
      sid       = "AllowAccountBuckets"
      effect    = "Allow"
      resources = ["*"]
      actions   = ["*"]

      condition {
        test     = "StringEquals"
        variable = "s3:ResourceAccount"
        values = [
          data.aws_caller_identity.current.account_id
        ]
      }

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }

  dynamic "statement" {
    # If we're using docker, grant access to the ECR bucket
    for_each = lookup(var.endpoints, "ecr.dkr", false) ? [0] : []

    content {
      sid    = "AccessECRBuckets"
      effect = "Allow"

      resources = [
        "arn:aws:s3:::prod-${data.aws_region.current.name}-starport-layer-bucket/*",
      ]

      actions = ["s3:GetObject"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }

  dynamic "statement" {
    # If we're using SSM, grant access to the SSM buckets
    for_each = var.endpoints["ssm"] ? [0] : []

    content {
      sid    = "AccessSSMBuckets"
      effect = "Allow"

      resources = [
        "arn:aws:s3:::amazon-ssm-packages-${data.aws_region.current.name}/*",
        "arn:aws:s3:::amazon-ssm-${data.aws_region.current.name}/*",
        "arn:aws:s3:::aws-patchmanager-macos-${data.aws_region.current.name}/*",
        "arn:aws:s3:::aws-ssm-document-attachments-${data.aws_region.current.name}/*",
        "arn:aws:s3:::aws-ssm-${data.aws_region.current.name}/*",
        "arn:aws:s3:::aws-windows-downloads-${data.aws_region.current.name}/*",
        "arn:aws:s3:::patch-baseline-snapshot-${data.aws_region.current.name}/*",
        "arn:aws:s3:::${data.aws_region.current.name}-birdwatcher-prod/*",
      ]

      actions = ["s3:GetObject"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }
    }
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.this.id
  subnet_ids          = [for s in aws_subnet.private : s.id]
  policy              = each.key == "email-smtp" ? null : data.aws_iam_policy_document.interface_endpoints[each.value].json
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.interface_endpoint[each.key].id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-${replace(each.key, ".", "-")}"
    },
  )
}

data "aws_iam_policy_document" "interface_endpoints" {
  # Need to use the variable instead of aws_vpc_endpoint.interface resource to avoid circular dependencies
  for_each = local.interface_endpoints

  statement {
    actions = [
      "${split(".", each.key)[0]}:*",
    ]

    principals {
      type        = "*" # Allow all principals, not just IAM principals
      identifiers = ["*"]
    }

    resources = ["*"]

    condition {
      test     = length(var.org_units) > 0 ? "ForAnyValue:StringEquals" : "StringEquals"
      variable = length(var.org_units) > 0 ? "aws:ResourceOrgPaths" : "aws:ResourceOrgID"
      values   = local.org_paths
    }

    condition {
      test     = length(var.org_units) > 0 ? "ForAnyValue:StringEquals" : "StringEquals"
      variable = length(var.org_units) > 0 ? "aws:PrincipalOrgPaths" : "aws:PrincipalOrgID"
      values   = local.org_paths
    }
  }
}

resource "aws_security_group" "interface_endpoint" {
  # Need to use the variable instead of aws_vpc_endpoint.interface resource to avoid circular dependencies
  for_each = local.interface_endpoints

  name        = "vpce-${var.name}-${replace(each.value, ".", "-")}"
  description = "VPC endpoint for accessing ${each.value}"

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      "Name" = "vpce-${var.name}-${replace(each.value, ".", "-")}"
    },
  )
}

resource "aws_security_group_rule" "endpoint_ingress" {
  for_each = aws_vpc_endpoint.interface

  description = "Connect to ${each.key} endpoint."

  security_group_id = aws_security_group.interface_endpoint[each.key].id

  from_port   = each.key == "email-smtp" ? 587 : 443
  protocol    = "tcp"
  cidr_blocks = [for s in aws_subnet.private : s.cidr_block]
  to_port     = each.key == "email-smtp" ? 587 : 443
  type        = "ingress"
}
