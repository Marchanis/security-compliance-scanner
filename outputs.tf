output "dev_scanner_arn" {
  description = "arn of dev scanner"
  value       = module.dev_scanner.sns_topic_arn
}

output "production_scanner_arn" {
  description = "arn of production scanner "
  value       = module.production_scanner.sns_topic_arn
}

output "dev_lambda_arn" {
  description = "arn of dev Lambda function"
  value       = module.dev_scanner.lambda_function_arn
}

output "production_lambda_arn" {
  description = "arn of production Lambda function "
  value       = module.production_scanner.lambda_function_arn
}

output "dev_schedule_arn" {
  description = "arn of dev EventBridge schedule"
  value       = module.dev_scanner.scheduler_arn
}

output "production_schedule_arn" {
  description = "arn of production EventBridge schedule "
  value       = module.production_scanner.scheduler_arn
}

output "dev_scheduler_role_arn" {
  description = "arn of dev Scheduler IAM role"
  value       = module.dev_scanner.scheduler_role_arn
}

output "production_scheduler_role_arn" {
  description = "arn of production Scheduler IAM role "
  value       = module.production_scanner.scheduler_role_arn
}

output "dev_topic_subscription_arn" {
  description = "arn of production topic subscription  "
  value       = module.dev_scanner.topic_subscription_arn
}


output "production_topic_subscription_arn" {
  description = "arn of production topic subscription  "
  value       = module.production_scanner.topic_subscription_arn
}
