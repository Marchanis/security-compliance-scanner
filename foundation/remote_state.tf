data "terraform_remote_state" "owner" {
  backend = "s3"

  config = {
    bucket = "flask-terraform-state-sall"
    key    = "security-compliance-scanner/terraform.tfstate"
    region = "us-east-1"

  }

}
