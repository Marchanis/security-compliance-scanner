# Security Compliance Scanner

An automated AWS security scanner that detects common misconfigurations across S3, EC2, RDS, and IAM, and emails a weekly report via SNS. Built with Python (boto3) and deployed entirely with Terraform.

## What it checks

- **S3** — buckets with a public bucket policy
- **EC2** — security groups with SSH (port 22) or all-traffic rules open to `0.0.0.0/0`
- **RDS** — unencrypted instances and publicly accessible instances
- **IAM** — users without MFA enabled

This is a **detection-only** tool (v1) — it reports findings, it does not auto-remediate.

## Architecture

- **Lambda** (`lambda_function.py`) — orchestrator that runs all 4 checks and publishes the combined report
- **SNS** — delivers the report by email
- **EventBridge Scheduler** — triggers the Lambda automatically, once a week
- **IAM** — least-privilege role for the Lambda (only the exact permissions its checks require), plus a separate role for the scheduler to invoke Lambda

## Project structure

lambda/
├── lambda_function.py   # entry point, combines checks, publishes to SNS
├── check_s3.py
├── check_ec2.py
├── check_rds.py
└── check_iam.py

backend.tf
provider.tf
variables.tf
sns.tf
iam.tf
lambda.tf
eventbridge.tf

## Deploy

```bash
terraform init
terraform apply
```

Requires a `terraform.tfvars` file with:

```hcl
sns_email = "your-email@example.com"
```

After applying, confirm the SNS subscription email before reports will arrive.

## Test manually

```bash
aws lambda invoke --function-name security-compliance-scanner output.json
cat output.json
```

## Known limitations (v1)

- S3 check only covers bucket policies, not ACLs or Block Public Access settings
- No auto-remediation — findings must be fixed manually
