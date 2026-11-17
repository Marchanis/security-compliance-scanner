data "aws_caller_identity" "current" {}

resource "aws_iam_role" "github_actions_ci" {
  name = "github-action-oidc"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:Marchanis@118909843/security-compliance-scanner@1311031454:pull_request",
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }

      },
    ]
    }

  )
}


resource "aws_iam_role_policy" "artifact_role" {
  name = "artifact-s3-access-role"
  role = aws_iam_role.github_actions_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.artifact_s3_bucket_scanner.arn}/*"

      }
    ]
  })
}

resource "aws_iam_role_policy" "root_state_s3_role" {
  name = "root-state-read-access"
  role = aws_iam_role.github_actions_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/terraform.tfstate"

      }
    ]
  })
}







resource "aws_iam_role" "dev_deployment" {
  name = "security-compliance-scanner-dev-deployment"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:Marchanis@118909843/security-compliance-scanner@1311031454:environment:dev",
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }

      },
    ]
    }

  )
}




resource "aws_iam_role_policy" "dev_permission_artifact" {
  name = "dev-artifact-s3-read"
  role = aws_iam_role.dev_deployment.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.artifact_s3_bucket_scanner.arn}/*"


      }
    ]
  })
}


resource "aws_iam_role_policy" "dev_iam_permissions" {
  name = "security-compliance-scanner-env-iam-permissions"
  role = aws_iam_role.dev_deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:PutRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-dev-*"

      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-dev-lambda-role"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-dev-lambda-role"
        Condition = {
          StringEquals = {
            "iam:PolicyARN" = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
          }
        }
      }
    ]
  })
}



resource "aws_iam_role" "production_deployment" {
  name = "security-compliance-scanner-production-deployment"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:Marchanis@118909843/security-compliance-scanner@1311031454:environment:production",
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }

      },
    ]
    }

  )
}



resource "aws_iam_role_policy" "pro_permission_artifact" {
  name = "production-artifact-s3-read"
  role = aws_iam_role.production_deployment.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.artifact_s3_bucket_scanner.arn}/*"


      }
    ]
  })
}


resource "aws_iam_role_policy" "production_iam_permissions" {
  name = "security-compliance-scanner-production-iam-permissions"
  role = aws_iam_role.production_deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:PutRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-production-*"

      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-production-lambda-role"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-production-lambda-role"
        Condition = {
          StringEquals = {
            "iam:PolicyARN" = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
          }
        }
      }
    ]
  })

}

resource "aws_iam_policy" "dev_lambda_boundary" {
  name = "security-compliance-scanner-dev-lambda-boundary"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketPolicyStatus"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:ListMFADevices"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = data.terraform_remote_state.owner.outputs.dev_scanner_arn


      },
    ]
  })
}



resource "aws_iam_policy" "production_lambda_boundary" {
  name = "security-compliance-scanner-production-lambda-boundary"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketPolicyStatus"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:ListMFADevices"
        ]
        Resource = "*"


      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = data.terraform_remote_state.owner.outputs.production_scanner_arn


      },
    ]
  })
}



resource "aws_iam_role_policy" "dev_service_permissions" {
  name = "security-compliance-scanner-dev-service-permissions"
  role = aws_iam_role.dev_deployment.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:UpdateFunctionCode",
          "lambda:DeleteFunction",
          "lambda:CreateFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = data.terraform_remote_state.owner.outputs.dev_lambda_arn

      },
      {
        Effect = "Allow"
        Action = [
          "scheduler:CreateSchedule",
          "scheduler:DeleteSchedule",
          "scheduler:GetSchedule",
          "scheduler:UpdateSchedule"
        ]
        Resource = data.terraform_remote_state.owner.outputs.dev_schedule_arn

      },
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe",
          "sns:CreateTopic",
          "sns:GetTopicAttributes",
          "sns:DeleteTopic",
          "sns:ListSubscriptionsByTopic",
          "sns:SetTopicAttributes",



        ]
        Resource = data.terraform_remote_state.owner.outputs.dev_scanner_arn


      },
      {
        Effect = "Allow"
        Action = [
          "sns:Unsubscribe",
          "sns:GetSubscriptionAttributes"
        ]
        Resource = data.terraform_remote_state.owner.outputs.dev_topic_subscription_arn
      }

    ]

  })
}



resource "aws_iam_role_policy" "production_service_permissions" {
  name = "security-compliance-scanner-production-service-permissions"
  role = aws_iam_role.production_deployment.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:UpdateFunctionCode",
          "lambda:DeleteFunction",
          "lambda:CreateFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = data.terraform_remote_state.owner.outputs.production_lambda_arn

      },
      {
        Effect = "Allow"
        Action = [
          "scheduler:CreateSchedule",
          "scheduler:DeleteSchedule",
          "scheduler:GetSchedule",
          "scheduler:UpdateSchedule"
        ]
        Resource = data.terraform_remote_state.owner.outputs.production_schedule_arn

      },
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe",
          "sns:CreateTopic",
          "sns:GetTopicAttributes",
          "sns:DeleteTopic",
          "sns:ListSubscriptionsByTopic",
          "sns:SetTopicAttributes",
        ]
        Resource = data.terraform_remote_state.owner.outputs.production_scanner_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Unsubscribe",
          "sns:GetSubscriptionAttributes"
        ]
        Resource = data.terraform_remote_state.owner.outputs.production_topic_subscription_arn
      }
    ]

  })
}

resource "aws_iam_role_policy" "dev_scheduler_iam_permissions" {
  name = "dev-scheduler-iam-permissions"
  role = aws_iam_role.dev_deployment.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = data.terraform_remote_state.owner.outputs.dev_scheduler_role_arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "scheduler.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies"
        ]
        Resource = data.terraform_remote_state.owner.outputs.dev_scheduler_role_arn
      }
    ]
  })
}





resource "aws_iam_role_policy" "production_scheduler_iam_permissions" {
  name = "production-scheduler-iam-permissions"
  role = aws_iam_role.production_deployment.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = data.terraform_remote_state.owner.outputs.production_scheduler_role_arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "scheduler.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies"
        ]
        Resource = data.terraform_remote_state.owner.outputs.production_scheduler_role_arn
      }
    ]
  })
}













