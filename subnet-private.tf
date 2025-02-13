locals {
  private_subnet_base   = cidrsubnet(var.ipv4_cidr_block, 1, 0)
  private_subnets_cidrs = { for az in local.azs : az => cidrsubnet(local.private_subnet_base, 3, index(local.azs, az)) }
}

resource "aws_subnet" "private" {
  for_each = toset(local.azs)

  vpc_id     = aws_vpc.this.id
  cidr_block = local.private_subnets_cidrs[each.value]

  availability_zone = each.value

  tags = {
    "Name"    = "${var.name}-private-${each.value}"
    "Network" = "Private"
  }
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = {
    Name    = "${var.name}-private-${each.key}"
    Network = "Private"
  }
}

resource "aws_route_table_association" "private_subnets" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_eip" "nat_gateway" {
  for_each = aws_subnet.private

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-natgw-${each.key}",
      Network = "Private"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = aws_eip.nat_gateway

  allocation_id = each.value.id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-${each.key}",
      Network = "Private"
  })
}
