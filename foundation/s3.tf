resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = "flask-terraform-state-sall"

  versioning_configuration {
    status = "Enabled"
  }
}

