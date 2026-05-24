# AWS Shared VPC Module

Terraform module for a shared VPC with public and private subnets, NAT gateways,
VPC endpoints, network ACLs, flow logs, DNS query logging, and RAM sharing.

## Prerequisites

- **AWS Organizations** — the account must be a member. Endpoint policies and
  RAM sharing are scoped to the Organization.
- **S3 buckets** — one for VPC flow logs, one for Route 53 DNS query logs.
  These must already exist. The same bucket can be shared
- **Terraform** >= 1.10.0 and **AWS provider** >= 5.0 (6+ recommended).

## Usage

```hcl
module "vpc" {
  source = "path/to/module"

  name                 = "shared"
  logging_bucket_dns   = "my-org-dns-logs"
  logging_bucket_flows = "my-org-flow-logs"

  tags = {
    Environment = "production"
  }
}
```

## Key Behaviours

### Subnet Layout

The VPC CIDR is split in half: the lower half is private, the upper half is
public. Each half is divided into /24 subnets, one per AZ. With the default
CIDR `10.128.0.0/16` this gives 254 usable IPs per subnet and supports up to
8 AZs.

### NAT Gateways

One NAT gateway per AZ by default. Set `natgw_per_subnet = false` for a single
shared gateway (cheaper, but a single point of failure).

### Default Security Group

Managed as empty and tagged `DO-NOT-USE`. No ingress or egress rules — this
prevents accidental use.

### Network ACLs

Private subnets have a custom NACL:
- **Inbound** — allow all traffic from VPC CIDR; allow TCP/UDP 1024-65535 from
  `0.0.0.0/0` (NAT gateway return traffic).
- **Outbound** — allow all.

Public subnets use the default NACL (allow all).

### VPC Endpoints

S3 and DynamoDB **gateway** endpoints are always created (they are free). All
endpoint policies restrict access to the AWS Organization.

**Interface** endpoints are opt-in via the `endpoints` variable. Setting
`ecr.dkr` or `ssm` to `true` also adds service-specific S3 bucket policy
statements to the S3 gateway endpoint.

```hcl
endpoints = {
  "ecr.dkr"    = true
  "ssm"        = true
  "email-smtp" = true  # uses port 587 instead of 443
}
```

### RAM Sharing

All subnets are shared via AWS RAM with the Organization. To restrict sharing
to specific OUs, pass `org_units`.

### SSM Parameters

The module publishes the following SSM parameters under `/{name}/network/`:
- `vpc` — VPC ID
- `subnets_private` — map of AZ to private subnet ID
- `subnets_public` — map of AZ to public subnet ID
- `nat_gateway_ips` — list of NAT gateway public IPs
- `vpc_endpoints` — gateway and interface endpoint details

### Logging

- **Flow logs** — all traffic, delivered to `s3://{logging_bucket_flows}/vpc`.
- **DNS query logs** — delivered to
  `s3://{logging_bucket_dns}/route53resolver`.

### Tags

At least one tag is required and the `Environment` key must be present.

# Generated Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_default_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) | resource |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_rule.private_egress_allow_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_ingress_allow_return_traffic_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_ingress_allow_return_traffic_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_ingress_allow_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_ram_principal_association.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.subnet_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_association.subnet_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |
| [aws_route.private_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route53_resolver_query_log_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_query_log_config) | resource |
| [aws_route53_resolver_query_log_config_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_query_log_config_association) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.interface_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.endpoint_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.nat_gateway_ips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.subnets_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.subnets_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.gateway_dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.gateway_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.endpoint_gateway_dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.endpoint_gateway_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.interface_endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_azs"></a> [azs](#input\_azs) | List of AWS Availability Zones to use for deploying resources. If empty all AZs in region used. | `list(string)` | `[]` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | VPC interface endpoints to enable. S3 and DynamoDB gateway endpoints are always provisioned (free). Keys are AWS service names (e.g. ecr.dkr, ssm). Setting s3 or dynamodb here also enables service-specific S3 policy statements. | `map(bool)` | `{}` | no |
| <a name="input_ipv4_cidr_block"></a> [ipv4\_cidr\_block](#input\_ipv4\_cidr\_block) | CIDR block for the VPC. | `string` | `"10.128.0.0/16"` | no |
| <a name="input_logging_bucket_dns"></a> [logging\_bucket\_dns](#input\_logging\_bucket\_dns) | Name of the S3 bucket to use for logging DNS requests. | `string` | n/a | yes |
| <a name="input_logging_bucket_flows"></a> [logging\_bucket\_flows](#input\_logging\_bucket\_flows) | Name of the S3 bucket to use for logging VPC flows. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the VPC. | `string` | n/a | yes |
| <a name="input_natgw_per_subnet"></a> [natgw\_per\_subnet](#input\_natgw\_per\_subnet) | Create a NAT gateway per private subnet. When false, all private subnets share a single NAT gateway. At least one NAT gateway is always provisioned. | `bool` | `true` | no |
| <a name="input_org_units"></a> [org\_units](#input\_org\_units) | Map of of OU OrgPaths -> ARNs that can access the VPC. If empty access is limited to the Organization. | <pre>map(<br/>    object({<br/>      arn  = string<br/>      path = string<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to add resources provisioned. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_azs"></a> [azs](#output\_azs) | List of availability zones used by this VPC |
| <a name="output_endpoint_security_groups"></a> [endpoint\_security\_groups](#output\_endpoint\_security\_groups) | Mapping of endpoints to security group IDs |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | ID of the Internet Gateway |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | Map of AZ to NAT Gateway ID |
| <a name="output_nat_gateway_ips"></a> [nat\_gateway\_ips](#output\_nat\_gateway\_ips) | Public IPs of the NAT gateways |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | Map of AZ to private route table ID |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | ID of the public route table |
| <a name="output_ssm_endpoints"></a> [ssm\_endpoints](#output\_ssm\_endpoints) | ARN of the SSM parameter containing the VPC endpoint configuration |
| <a name="output_ssm_nat_gateway_ips"></a> [ssm\_nat\_gateway\_ips](#output\_ssm\_nat\_gateway\_ips) | ARN of the SSM parameter containing the NAT Gateway IPs |
| <a name="output_ssm_subnets_private"></a> [ssm\_subnets\_private](#output\_ssm\_subnets\_private) | ARN of the SSM parameter containing the private subnets |
| <a name="output_ssm_subnets_public"></a> [ssm\_subnets\_public](#output\_ssm\_subnets\_public) | ARN of the SSM parameter containing the public subnets |
| <a name="output_ssm_vpc"></a> [ssm\_vpc](#output\_ssm\_vpc) | ARN of the SSM parameter containing the VPC ID |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | Subnets configured for the VPC |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | ARN of the VPC |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
<!-- END_TF_DOCS -->