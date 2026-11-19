variable "aws_region" {
  description = "the AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "SNS_EMAIL" {
  description = "sns email"
  type        = string
  sensitive   = true
}
