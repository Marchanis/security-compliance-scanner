terraform {
  backend "s3" {
    bucket       = "flask-terraform-state-sall"
    key          = "security-compliance-scanner/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
  required_version = ">= 1.5.0"
}