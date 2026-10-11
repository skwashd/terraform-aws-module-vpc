# AWS Shared VPC Module

This Terraform module creates a VPC that you share with the accounts in your
AWS organization. The module creates these items:

- A public subnet and a private subnet in each Availability Zone (AZ)
- NAT gateways for the private subnets
- VPC endpoints
- A network ACL for the private subnets
- VPC flow logs and DNS query logs
- An AWS RAM resource share for the subnets

## Prerequisites

- **AWS Organizations**: The account must be a member of an organization. The
  endpoint policies and the RAM share use the organization to control access.
- **S3 buckets**: You need one bucket for VPC flow logs and one bucket for
  Route 53 DNS query logs. Create the buckets before you use the module. You
  can use one bucket for the two types of logs.
- **Terraform**: Version 1.10.0 or later.
- **AWS provider**: Version 6.0 or later.

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

## Key Behavior

### Subnet Layout

The module divides the VPC CIDR block into two halves. The lower half is for
the private subnets. The upper half is for the public subnets.

The module divides each half into eight equal subnets. Each AZ gets one
private subnet and one public subnet. As a result, the module supports a
maximum of eight AZs.

With the default CIDR block `10.128.0.0/16`, each subnet is a /20. A /20
subnet has 4,091 usable IP addresses, because AWS reserves five addresses in
each subnet.

### NAT Gateways

By default, the module creates one NAT gateway in each AZ.

If you set `natgw_per_subnet = false`, the module creates one NAT gateway in
the first AZ. All private subnets use this gateway. This option costs less.
But if the first AZ fails, the private subnets in all AZs lose internet access.

### Default Security Group

The module removes all rules from the default security group of the VPC. It
also adds `DO-NOT-USE` to the `Name` tag of the group. As a result, a resource
that uses the default security group gets no network access.

### Network ACLs

The private subnets use a custom network ACL with these rules:

- **Inbound**: Allow all traffic from the VPC CIDR block. Allow TCP and UDP
  ports 1024-65535 from `0.0.0.0/0` for return traffic through the NAT
  gateways.
- **Outbound**: Allow all traffic.

The public subnets use the default network ACL. This network ACL allows all
traffic.

### VPC Endpoints

The module always creates the S3 and DynamoDB gateway endpoints, because
gateway endpoints are free.

Interface endpoints are optional. To create them, add the service names to the
`endpoints` variable:

```hcl
endpoints = {
  "ecr.dkr"    = true
  "ssm"        = true
  "email-smtp" = true # uses port 587 instead of 443
}
```

The module puts each interface endpoint in all private subnets and enables
private DNS. The security group of each endpoint accepts traffic only from the
private subnets. The `email-smtp` endpoint uses port 587. All other interface
endpoints use port 443.

The endpoint policies give access only to principals and resources in your
organization. These are the exceptions:

- The `email-smtp` endpoint has no endpoint policy.
- If `ecr.dkr` is true, the S3 gateway endpoint also gives access to the AWS
  bucket that holds ECR image layers.
- If `ssm` is true, the S3 gateway endpoint also gives access to the AWS
  buckets that SSM uses.

### RAM Sharing

The module uses AWS RAM to share all subnets. By default, it shares the
subnets with the full organization. To share them only with specific
organizational units (OUs), set `org_units`. The share does not accept
principals from outside the organization.

### SSM Parameters

The module writes these SSM parameters under `/{name}/network/`:

- `vpc`: The VPC ID.
- `subnets_private`: A map of AZ to private subnet ID.
- `subnets_public`: A map of AZ to public subnet ID.
- `nat_gateway_ips`: A list of the public IP addresses of the NAT gateways.
- `vpc_endpoints`: The IDs, prefix lists, and security groups of the
  endpoints.

### Logging

- **Flow logs**: The VPC sends logs for all traffic to
  `s3://{logging_bucket_flows}/vpc`.
- **DNS query logs**: Route 53 Resolver sends DNS query logs to
  `s3://{logging_bucket_dns}/route53resolver`.

### Tags

The `tags` variable must contain the `Environment` key. The module applies
these tags to all resources that support tags.

## Upgrade Notes

### Security Group Rules for Interface Endpoints

Older versions of the module use one `aws_security_group_rule` for each
interface endpoint. This version uses one `aws_vpc_security_group_ingress_rule`
for each interface endpoint and private subnet. Terraform cannot move the old
rules to the new resource type.

CAUTION: Do steps 1 to 3 without a pause. Between step 1 and step 3, the
private subnets cannot connect to the interface endpoints.

1. Before you change the module version, remove the old rules. Replace
   `module.vpc` with the address of your module.

   ```sh
   terraform destroy -target='module.vpc.aws_security_group_rule.endpoint_ingress'
   ```

2. Change the module version.
3. Run `terraform apply`.

If you do not do step 1, the first `terraform apply` can fail with
`InvalidPermission.Duplicate`. If this occurs, run `terraform apply` again.

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
| [aws_vpc_security_group_ingress_rule.interface_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
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
| <a name="input_azs"></a> [azs](#input\_azs) | Availability Zones (AZs) to use. If the list is empty, the module uses all available AZs in the region. | `list(string)` | `[]` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | Interface VPC endpoints to create. Each key is an AWS service name, for example ecr.dkr or ssm. The module always creates the S3 and DynamoDB gateway endpoints, so it ignores the s3 and dynamodb keys. If ecr.dkr or ssm is true, the S3 gateway endpoint policy also gives access to the AWS buckets of that service. | `map(bool)` | `{}` | no |
| <a name="input_ipv4_cidr_block"></a> [ipv4\_cidr\_block](#input\_ipv4\_cidr\_block) | CIDR block for the VPC. | `string` | `"10.128.0.0/16"` | no |
| <a name="input_logging_bucket_dns"></a> [logging\_bucket\_dns](#input\_logging\_bucket\_dns) | Name of the S3 bucket for Route 53 DNS query logs. | `string` | n/a | yes |
| <a name="input_logging_bucket_flows"></a> [logging\_bucket\_flows](#input\_logging\_bucket\_flows) | Name of the S3 bucket for VPC flow logs. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the VPC. | `string` | n/a | yes |
| <a name="input_natgw_per_subnet"></a> [natgw\_per\_subnet](#input\_natgw\_per\_subnet) | If true, the module creates one NAT gateway in each AZ. If false, the module creates one NAT gateway in the first AZ, and all private subnets use it. | `bool` | `true` | no |
| <a name="input_org_units"></a> [org\_units](#input\_org\_units) | Organizational units (OUs) to share the subnets with. Each value contains the ARN and the path of an OU. If the map is empty, the module shares the subnets with the full organization. | <pre>map(<br/>    object({<br/>      arn  = string<br/>      path = string<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources that support tags. The map must contain the Environment key. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_azs"></a> [azs](#output\_azs) | List of availability zones used by this VPC |
| <a name="output_endpoint_security_groups"></a> [endpoint\_security\_groups](#output\_endpoint\_security\_groups) | Gateway and interface VPC endpoints: IDs, prefix lists and security group IDs |
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
| <a name="output_subnets"></a> [subnets](#output\_subnets) | Private and public subnets: map of AZ to subnet ID and ARN |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | ARN of the VPC |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
<!-- END_TF_DOCS -->