terraform {
  required_version = "> 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      version = "~> 6.13"
      source  = "hashicorp/aws"
    }
  }
}
