locals {
  public_subnet_base   = cidrsubnet(var.ipv4_cidr_block, 1, 1)
  public_subnets_cidrs = { for az in local.azs : az => cidrsubnet(local.public_subnet_base, 3, index(local.azs, az)) }
}

resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  vpc_id     = aws_vpc.this.id
  cidr_block = local.public_subnets_cidrs[each.value]

  availability_zone = each.value

  tags = {
    Name      = "${var.name}-public-${each.value}"
    "Network" = "Public"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name    = var.name,
      Network = "Public"
    },
  )
}

resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-public",
      Network = "Public"
    },
  )
}

resource "aws_route_table_association" "public_subnets" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_default_route_table.this.id
}
