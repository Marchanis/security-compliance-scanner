resource "aws_iam_role" "lambda_execution_role" {
  name = "security-compliance-scanner-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
    }

  )
}
resource "aws_iam_role_policy" "custom_policy" {
  name = "security-compliance-scanner-inline-permissions"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketPolicyStatus",
          "ec2:DescribeSecurityGroups",
          "rds:DescribeDBInstances",
          "iam:ListUsers",
          "iam:ListMFADevices",
          "sns:Publish",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "github_actions_ci" {
  name = "github-action-oidc"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::889992886230:oidc-provider/token.actions.githubusercontent.com"
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

resource "aws_iam_role_policy_attachment" "permission_policy" {
  role       = aws_iam_role.github_actions_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}