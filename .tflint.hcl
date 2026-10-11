tflint {
  required_version = ">= 0.64.0"
}

plugin "aws" {
  enabled = true
  version = "0.49.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "dave-says" {
  enabled = true
  version = "0.4.0"
  source  = "github.com/skwashd/tflint-ruleset-dave-says"
}
