
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "scanner" {
  source                   = "../../modules/scanner"
  function_name            = "security-scanner-dev"
  lambda_timeout           = 60
  environment              = "dev"
  topic_name               = "dev_scanner_alert"
  sns_email                = var.sns_email
  permissions_boundary_arn = data.terraform_remote_state.foundation.outputs.dev_permission_boundary_arn

}

data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = "flask-terraform-state-sall"
    key    = "security-compliance-scanner-env/terraform.tfstate"
    region = "us-east-1"
  }
}