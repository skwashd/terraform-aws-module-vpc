resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-private"
      Network = "Private"
    },
  )
}

resource "aws_network_acl_rule" "private_ingress_allow_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.this.cidr_block
}

# Ephemeral port range starts at 1024 rather than 32768 (the Linux default)
# because AWS NAT Gateways select source ports from 1024-65535.
resource "aws_network_acl_rule" "private_ingress_allow_return_traffic_tcp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_ingress_allow_return_traffic_udp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 210
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_egress_allow_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
