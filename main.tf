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

module "dev_scanner" {
  source         = "./modules/scanner"
  function_name  = "security-scanner-dev"
  lambda_timeout = 60
  environment    = "dev"
  topic_name     = "dev_scanner_alert"
  sns_email      = var.SNS_EMAIL
  # permissions_boundary_arn = data.terraform_remote_state.foundation.outputs.dev_permission_boundary_arn


}

module "production_scanner" {
  source         = "./modules/scanner"
  function_name  = "security-scanner-production"
  lambda_timeout = 60
  environment    = "production"
  topic_name     = "production_scanner_alert"
  sns_email      = var.SNS_EMAIL
  # permissions_boundary_arn = data.terraform_remote_state.foundation.outputs.production_permission_boundary_arn


}