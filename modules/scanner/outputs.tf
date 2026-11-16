output "sns_topic_arn" {
  value = aws_sns_topic.sns_topic.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "scheduler_arn" {
  value = aws_scheduler_schedule.weekly_schedule.arn
}

output "scheduler_role_arn" {
  value = aws_iam_role.scheduler_role.arn
}

output "topic_subscription_arn" {
  value = aws_sns_topic_subscription.sns_topic_subscription.arn
}