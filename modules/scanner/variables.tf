variable "function_name" {
  description = "variable that controls the Lambda function's name"
  type        = string
}


variable "lambda_timeout" {
  description = "Maximum execution time for the scanner"
  type        = number
}

variable "environment" {
  description = "Deployment environment (dev or production)"
  type        = string
}

variable "topic_name" {
  description = "SNS topic name"
  type        = string
}

variable "SNS_EMAIL" {
  description = "SNS subscription email"
  type        = string
}

variable "permissions_boundary_arn" {
  description = "arn of permission boundary"
  type        = string
  default     = null
}