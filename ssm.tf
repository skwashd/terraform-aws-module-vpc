resource "aws_ssm_parameter" "endpoints" {
  name = "/${var.name}/network/vpc_endpoints"
  type = "String"
  value = jsonencode({
    gateway   = local.vpc_endpoints_gateway
    interface = local.vpc_endpoints_interface
  })

  tags = var.tags
}

resource "aws_ssm_parameter" "nat_gateway_ips" {
  name        = "/${var.name}/network/nat_gateway_ips"
  description = "List of IP addresses associated with the NAT Gateways"
  type        = "String"
  value       = jsonencode([for _, ngw in aws_eip.nat_gateway : ngw.public_ip])

  tags = var.tags
}


resource "aws_ssm_parameter" "subnets_private" {
  name        = "/${var.name}/network/subnets_private"
  description = "Map of private subnets. AZ -> subnet ID"
  type        = "String"
  value       = jsonencode({ for az, subnet in aws_subnet.private : az => subnet.id })

  tags = var.tags
}

resource "aws_ssm_parameter" "subnets_public" {
  name        = "/${var.name}/network/subnets_public"
  description = "Map of public subnets. AZ -> subnet ID"
  type        = "String"
  value       = jsonencode({ for az, subnet in aws_subnet.public : az => subnet.id })

  tags = var.tags
}

resource "aws_ssm_parameter" "vpc" {
  name  = "/${var.name}/network/vpc"
  type  = "String"
  value = jsonencode(aws_vpc.this.id)

  tags = var.tags
}
