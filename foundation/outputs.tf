output "dev_permission_boundary_arn" {
  value = aws_iam_policy.dev_lambda_boundary.arn
}

output "production_permission_boundary_arn" {
  value = aws_iam_policy.production_lambda_boundary.arn

}