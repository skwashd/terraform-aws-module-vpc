resource "aws_route53_resolver_query_log_config" "this" {
  name            = var.name
  destination_arn = "${data.aws_s3_bucket.logging_bucket_dns.arn}/route53-resolver/${var.name}"

  tags = var.tags
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  resource_id = aws_vpc.this.id

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this.id
}
