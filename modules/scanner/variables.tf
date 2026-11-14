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