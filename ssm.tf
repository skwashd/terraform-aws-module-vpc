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

resource "aws_ssm_parameter" "endpoints" {
  name = "/${var.name}/network/vpc_endpoints"
  type = "String"
  value = jsonencode({
    gateway   = local.vpc_endpoints_gateway
    interface = local.vpc_endpoints_interface
  })

  tags = var.tags
}
