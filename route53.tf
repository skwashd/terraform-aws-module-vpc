resource "aws_route53_resolver_query_log_config" "this" {
  name = var.name
  destination_arn = provider::aws::arn_build(
    data.aws_partition.current.partition,
    "s3",
    "",
    "",
    "${var.logging_bucket_dns}/route53resolver"
  )

  tags = var.tags
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  resource_id = aws_vpc.this.id

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this.id
}
