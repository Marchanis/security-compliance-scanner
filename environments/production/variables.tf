
variable "aws_region" {
  description = "AWS region for Production resources"
  type        = string
  default     = "us-east-1"
}

variable "SNS_EMAIL" {
  description = "Email address for Production scanner alerts"
  type        = string
  sensitive   = true
}
