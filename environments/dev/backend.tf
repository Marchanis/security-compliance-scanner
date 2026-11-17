terraform {
  backend "s3" {
    bucket       = "flask-terraform-state-sall"
    key          = "security-compliance-scanner/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
