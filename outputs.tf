output "azs" {
  description = "List of availability zones used by this VPC"
  value       = local.azs
}

output "endpoint_security_groups" {
  description = "Mapping of endpoints to security group IDs"
  value = {
    gateway   = local.vpc_endpoints_gateway
    interface = local.vpc_endpoints_interface
  }
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "Map of AZ to NAT Gateway ID"
  value       = { for az, ngw in aws_nat_gateway.this : az => ngw.id }
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT gateways"
  value       = [for eip in aws_eip.nat_gateway : eip.public_ip]
}

output "private_route_table_ids" {
  description = "Map of AZ to private route table ID"
  value       = { for az, rt in aws_route_table.private : az => rt.id }
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_default_route_table.this.id
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
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}
