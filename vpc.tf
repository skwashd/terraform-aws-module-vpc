resource "aws_vpc" "this" {
  cidr_block = var.ipv4_cidr_block

  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_flow_log" "this" {
  log_destination      = "${data.aws_s3_bucket.logging_bucket_flows.arn}/vpc-flow-logs/${var.name}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id

  tags = var.tags
}

resource "aws_ram_resource_share" "vpc" {
  name = "vpc-${var.name}"

  allow_external_principals = false

  tags = merge({
    Name = "vpc-${var.name}"
    },
    var.tags
  )
}

resource "aws_ram_principal_association" "vpc" {
  for_each = local.shared_principals

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.vpc.arn
}

resource "aws_ram_resource_association" "subnet_private" {
  for_each = aws_subnet.private

  resource_arn       = each.value.arn
  resource_share_arn = aws_ram_resource_share.vpc.arn
}

resource "aws_ram_resource_association" "subnet_public" {
  for_each = aws_subnet.public

  resource_arn       = each.value.arn
  resource_share_arn = aws_ram_resource_share.vpc.arn
}
