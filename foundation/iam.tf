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
        Resource = aws_sns_topic.sns_topic.arn


      },
    ]
  })
}