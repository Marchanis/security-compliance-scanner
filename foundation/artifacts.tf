
resource "aws_s3_bucket" "artifact_s3_bucket_scanner" {
  bucket = "sal-security-compliance-artifacts"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "artifact_versioning" {
  bucket = aws_s3_bucket.artifact_s3_bucket_scanner.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "artifact_public_access" {
  bucket = aws_s3_bucket.artifact_s3_bucket_scanner.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifact_encryption" {
  bucket = aws_s3_bucket.artifact_s3_bucket_scanner.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}



resource "aws_s3_bucket_policy" "artifact_https_only" {
  bucket = aws_s3_bucket.artifact_s3_bucket_scanner.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Deny"

        Principal = "*"

        Action = "s3:*"

        Resource = [
          aws_s3_bucket.artifact_s3_bucket_scanner.arn,
          "${aws_s3_bucket.artifact_s3_bucket_scanner.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

}

