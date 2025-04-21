output "endpoint_security_groups" {
  description = "Mapping of endpoints to security group IDs"
  value = {
    gateway   = local.vpc_endpoints_gateway
    interface = local.vpc_endpoints_interface
  }
}

output "ssm_endpoints" {
  description = "ARN of the SSM parameter containing the VPC endpoint configuration"
  value       = aws_ssm_parameter.endpoints.arn
}

output "ssm_nat_gateway_ips" {
  description = "ARN of the SSM parameter containing the NAT Gateway IPs"
  value       = aws_ssm_parameter.nat_gateway_ips.arn
}

output "ssm_subnets_private" {
  description = "ARN of the SSM parameter containing the private subnets"
  value       = aws_ssm_parameter.subnets_private.arn
}

output "ssm_subnets_public" {
  description = "ARN of the SSM parameter containing the public subnets"
  value       = aws_ssm_parameter.subnets_public.arn
}

output "ssm_vpc" {
  description = "ARN of the SSM parameter containing the VPC ID"
  value       = aws_ssm_parameter.vpc.arn
}

output "subnets" {
  description = "Subnets configured for the VPC"
  value = {
    private = { for az, subnet in aws_subnet.private : az => { id = subnet.id, arn = subnet.arn } }
    public  = { for az, subnet in aws_subnet.public : az => { id = subnet.id, arn = subnet.arn } }
  }
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}
