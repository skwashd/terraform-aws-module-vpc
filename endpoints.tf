locals {
  interface_endpoints = toset([for k, v in var.endpoints : k if k != "s3" && k != "dynamodb" && v == true])

  vpc_endpoints_interface = {
    for service, endpoint in aws_vpc_endpoint.interface : service => {
      id                = endpoint.id,
      security_group_id = aws_security_group.interface_endpoint[service].id
    }
  }
  vpc_endpoints_gateway = {
    s3       = { id = aws_vpc_endpoint.gateway_s3.id, prefix_list = aws_vpc_endpoint.gateway_s3.prefix_list_id }
    dynamodb = { id = aws_vpc_endpoint.gateway_dynamodb.id, prefix_list = aws_vpc_endpoint.gateway_dynamodb.prefix_list_id }
  }
}

resource "aws_vpc_endpoint" "gateway_dynamodb" {
  vpc_id          = aws_vpc.this.id
  policy          = data.aws_iam_policy_document.endpoint_gateway_dynamodb.json
  service_name    = "com.amazonaws.${data.aws_region.current.region}.dynamodb"
  route_table_ids = [for table in aws_route_table.private : table.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-dynamodb"
    },
  )
}

data "aws_iam_policy_document" "endpoint_gateway_dynamodb" {
  statement {
    sid       = "AllowOrgTables"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:ListTables",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceOrgID"
      values = [
        data.aws_organizations_organization.this.id
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = [
        data.aws_organizations_organization.this.id
      ]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_vpc_endpoint" "gateway_s3" {
  vpc_id       = aws_vpc.this.id
  policy       = data.aws_iam_policy_document.endpoint_gateway_s3.json
  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"

  route_table_ids = [
    for table in aws_route_table.private : table.id
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-s3"
    },
  )
}

data "aws_iam_policy_document" "endpoint_gateway_s3" {
  statement {
    sid       = "AllowOrgBuckets"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "s3:AbortMultipartUpload",
      "s3:CompleteMultipartUpload",
      "s3:CreateMultipartUpload",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:ListObjectVersions",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:UploadPart",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceOrgID"
      values = [
        data.aws_organizations_organization.this.id
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = [
        data.aws_organizations_organization.this.id
      ]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  dynamic "statement" {
    # If we're using docker, grant access to the ECR bucket
    for_each = lookup(var.endpoints, "ecr.dkr", false) ? [0] : []

    content {
      sid    = "AccessECRBuckets"
      effect = "Allow"

      resources = [
        "arn:aws:s3:::prod-${data.aws_region.current.region}-starport-layer-bucket/*",
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
    for_each = lookup(var.endpoints, "ssm", false) ? [0] : []

    content {
      sid    = "AccessSSMBuckets"
      effect = "Allow"

      resources = [
        "arn:aws:s3:::amazon-ssm-packages-${data.aws_region.current.region}/*",
        "arn:aws:s3:::amazon-ssm-${data.aws_region.current.region}/*",
        "arn:aws:s3:::aws-patchmanager-macos-${data.aws_region.current.region}/*",
        "arn:aws:s3:::aws-ssm-document-attachments-${data.aws_region.current.region}/*",
        "arn:aws:s3:::aws-ssm-${data.aws_region.current.region}/*",
        "arn:aws:s3:::aws-windows-downloads-${data.aws_region.current.region}/*",
        "arn:aws:s3:::patch-baseline-snapshot-${data.aws_region.current.region}/*",
        "arn:aws:s3:::${data.aws_region.current.region}-birdwatcher-prod/*",
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
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.interface_endpoint[each.key].id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${replace(each.key, ".", "-")}"
    },
  )
}

data "aws_iam_policy_document" "interface_endpoints" {
  # Need to use the variable instead of aws_vpc_endpoint.interface resource to avoid circular dependencies
  for_each = local.interface_endpoints

  statement {
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*" # Allow all principals, not just IAM principals
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceOrgID"
      values = [
        data.aws_organizations_organization.this.id
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = [
        data.aws_organizations_organization.this.id
      ]
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
      Name = "vpce-${var.name}-${replace(each.value, ".", "-")}"
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
