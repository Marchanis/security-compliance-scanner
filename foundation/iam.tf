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
            "token.actions.githubusercontent.com:sub" = "repo:Marchanis@118909843/security-compliance-scanner@1311031454:environment:foundation",
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


resource "aws_iam_role_policy" "ci_environment_state_access" {
  name = "ci-environment-state-access"
  role = aws_iam_role.github_actions_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner-env/terraform.tfstate",
          "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/dev/terraform.tfstate",
          "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/production/terraform.tfstate"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/dev/terraform.tfstate.tflock",
          "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/production/terraform.tfstate.tflock",
          "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner-env/terraform.tfstate.tflock",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "security-compliance-scanner-env/terraform.tfstate",
              "security-compliance-scanner/dev/terraform.tfstate",
              "security-compliance-scanner/dev/terraform.tfstate.tflock",
              "security-compliance-scanner/production/terraform.tfstate",
              "security-compliance-scanner/production/terraform.tfstate.tflock",
              "security-compliance-scanner-env/terraform.tfstate.tflock",
            ]
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "terraform_plan_read" {
  name = "terraform-plan-read-access"
  role = aws_iam_role.github_actions_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-dev-lambda-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-production-lambda-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_dev",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_production",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-action-oidc",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-dev-deployment",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-production-deployment"

        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = [
          "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
          "arn:aws:iam::aws:policy/AdministratorAccess",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/security-compliance-scanner-dev-lambda-boundary",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/security-compliance-scanner-production-lambda-boundary"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:ListTags"
        ]
        Resource = [
          "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:security-scanner-dev",
          "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:security-scanner-production"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:GetTopicAttributes",
          "sns:ListSubscriptionsByTopic"
        ]
        Resource = [
          "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dev_scanner_alert",
          "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:production_scanner_alert"
        ]
      },
      {
        Effect = "Allow"
        Action = "sns:GetSubscriptionAttributes"
        Resource = [
          "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dev_scanner_alert:*",
          "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:production_scanner_alert:*"
        ]
      },
      {
        Effect = "Allow"
        Action = "scheduler:GetSchedule"
        Resource = [
          "arn:aws:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/security-compliance-weekly-schedule-dev",
          "arn:aws:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/security-compliance-weekly-schedule-production"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "scheduler:GetScheduleGroup"
        Resource = "arn:aws:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule-group/default"
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
        Effect   = "Allow"
        Action   = "iam:CreateRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-dev-lambda-role"
        Condition = {
          ArnEquals = {
            "iam:PermissionsBoundary" = aws_iam_policy.dev_lambda_boundary.arn
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "iam:CreateRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_dev"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:PutRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:DetachRolePolicy",
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-dev-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_dev"
        ]

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

resource "aws_iam_role" "foundation_deployment" {
  name = "security-compliance-scanner-foundation-deployment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"

        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:Marchanis@118909843/security-compliance-scanner@1311031454:environment:foundation"
          }
        }
      }
    ]
  })
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

resource "aws_iam_role" "foundation_restricted" {
  name = "security-compliance-scanner-foundation-restricted"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"

        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:Marchanis@118909843/security-compliance-scanner@1311031454:environment:foundation"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "foundation_backend_access" {
  name = "foundation-backend-access"
  role = aws_iam_role.foundation_restricted.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListFoundationStatePath"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "security-compliance-scanner-env/terraform.tfstate",
              "security-compliance-scanner-env/terraform.tfstate.tflock"
            ]
          }
        }
      },
      {
        Sid    = "InspectStateBucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
      },
      {
        Sid    = "AccessFoundationState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner-env/terraform.tfstate"
      },
      {
        Sid    = "ManageFoundationLock"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner-env/terraform.tfstate.tflock"
      },
      {
        Sid    = "ManageStateBucketVersioning"
        Effect = "Allow"
        Action = [
          "s3:PutBucketVersioning"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
      },
    ]
  })
}


resource "aws_iam_role_policy" "foundation_artifact_bucket_access" {
  name = "foundation-artifact-bucket-access"
  role = aws_iam_role.foundation_restricted.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateAndInspectArtifactBucket"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::sal-security-compliance-artifacts"
      },
      {
        Sid    = "ManageArtifactBucketSecurity"
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy"
        ]
        Resource = "arn:aws:s3:::sal-security-compliance-artifacts"
      },
      {
        Sid    = "ReadArtifactBucketSettings"
        Effect = "Allow"
        Action = [
          "s3:GetBucketCORS",
          "s3:GetBucketWebsite",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketLogging",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketTagging"
        ]
        Resource = "arn:aws:s3:::sal-security-compliance-artifacts"
      }
    ]
  })
}


resource "aws_iam_role_policy" "foundation_iam_read" {
  name = "foundation-iam-read-access"
  role = aws_iam_role.foundation_restricted.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadProjectRoles"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-action-oidc",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_*"
        ]
      },
      {
        Sid    = "ReadProjectPolicies"
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/security-compliance-scanner-*",
          "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
          "arn:aws:iam::aws:policy/AdministratorAccess"
        ]
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
        Effect   = "Allow"
        Action   = "iam:CreateRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-production-lambda-role"
        Condition = {
          ArnEquals = {
            "iam:PermissionsBoundary" = aws_iam_policy.production_lambda_boundary.arn
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "iam:CreateRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_production"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:PutRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:DetachRolePolicy",
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security-compliance-scanner-production-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_production"
        ]

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
          "logs:PutLogEvents",
          "logs:DescribeLogGroups"
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
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dev_scanner_alert"


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
          "logs:PutLogEvents",
          "logs:DescribeLogGroups"
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
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:production_scanner_alert"


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
          "lambda:UpdateFunctionConfiguration",
          "lambda:ListVersionsByFunction",
          "lambda:GetFunctionCodeSigningConfig",
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:security-scanner-dev"

      },
      {
        Effect = "Allow"
        Action = [
          "scheduler:CreateSchedule",
          "scheduler:DeleteSchedule",
          "scheduler:GetSchedule",
          "scheduler:UpdateSchedule"
        ]
        Resource = "arn:aws:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/security-compliance-weekly-schedule-dev"

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
          "sns:ListTagsForResource",
          "sns:GetSubscriptionAttributes",
          "sns:Unsubscribe",



        ]
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dev_scanner_alert"


      },
      {
        Effect = "Allow"
        Action = [
          "sns:Unsubscribe",
          "sns:GetSubscriptionAttributes"
        ]
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dev_scanner_alert:*"
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
          "lambda:UpdateFunctionConfiguration",
          "lambda:ListVersionsByFunction",
          "lambda:GetFunctionCodeSigningConfig",
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:security-scanner-production"
      },
      {
        Effect = "Allow"
        Action = [
          "scheduler:CreateSchedule",
          "scheduler:DeleteSchedule",
          "scheduler:GetSchedule",
          "scheduler:UpdateSchedule"
        ]
        Resource = "arn:aws:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/security-compliance-weekly-schedule-production"

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
          "sns:ListTagsForResource",
          "sns:GetSubscriptionAttributes",

        ]
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:production_scanner_alert"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Unsubscribe",
          "sns:GetSubscriptionAttributes"
        ]
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:production_scanner_alert:*"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_dev"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_dev"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_production"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/security_compliance_scheduler_role_production"
      }
    ]
  })
}


resource "aws_iam_role_policy" "dev_terraform_state" {
  name = "dev-terraform-state-access"
  role = aws_iam_role.dev_deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "security-compliance-scanner/dev/terraform.tfstate",
              "security-compliance-scanner/dev/terraform.tfstate.tflock",
              "security-compliance-scanner-env/terraform.tfstate",
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/dev/terraform.tfstate"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/dev/terraform.tfstate.tflock"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner-env/terraform.tfstate"
      }
    ]
  })
}

resource "aws_iam_role_policy" "production_terraform_state" {
  name = "production-terraform-state-access"
  role = aws_iam_role.production_deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::flask-terraform-state-sall"
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "security-compliance-scanner/production/terraform.tfstate",
              "security-compliance-scanner/production/terraform.tfstate.tflock",
              "security-compliance-scanner-env/terraform.tfstate",
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/production/terraform.tfstate"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner/production/terraform.tfstate.tflock"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::flask-terraform-state-sall/security-compliance-scanner-env/terraform.tfstate"
      }
    ]
  })
}










