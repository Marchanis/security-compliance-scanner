
variable "aws_region" {
  description = "AWS region for Dev resources"
  type        = string
  default     = "us-east-1"
}

variable "sns_email" {
  description = "Email address for Dev scanner alerts"
  type        = string
  sensitive   = true
}
