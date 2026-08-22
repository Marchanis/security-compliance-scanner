resource "aws_scheduler_schedule" "weekly_schedule" {
    name = "security-compliance-weekly-schedule"
    description = "Weekly schedule to trigger the lambda function"
    group_name = "default"

    schedule_expression = "cron(0 8 ? * TUE *)"
    schedule_expression_timezone = "Africa/Casablanca"

    flexible_time_window {
      mode = "OFF"
    }

    target {
        arn = aws_lambda_function.lambda_function.arn
        input = jsonencode({
            "message" = "Triggering the Lambda function from Eventbridge"
        })

        role_arn = aws_iam_role.scheduler_role.arn
    }
}


resource "aws_iam_role" "scheduler_role" {
  name = "security_compliance_scheduler_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"

            Effect = "Allow"
            Principal = {
                Service = "scheduler.amazonaws.com"
            }
        }
    ]
  })
}


resource "aws_iam_role_policy" "scheduler_invoke_policy" {
    name = "scheduler-invoke-lambda-permission"
    role = aws_iam_role.scheduler_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "lambda:InvokeFunction"
                ]
                Effect = "Allow"
                Resource = aws_lambda_function.lambda_function.arn
            }
        ]
    })
}