import boto3
import os 
import check_iam
import check_ec2
import check_rds
import check_s3


def lambda_handler(event, context):

    result = {
                    'checking_iam' : check_iam.check_iam_mfa(),
                    'checking_ec2' : check_ec2.check_ec2_sg(),
                    'checking_s3' : check_s3.check_public_buckets(),
                    'checking_rds' : check_rds.check_rds_encryption()
            }
    
    findings = {
        'IAM': result['checking_iam']['NO_MFA_Users'],
        'EC2_SSH': result['checking_ec2']['Security_Group'],
        'EC2_All_Traffic': result['checking_ec2']['All_Traffic'],
        'S3': result['checking_s3']['Public_bucket'],
        'RDS_Unencrypted': result['checking_rds']['RDS_unencrypted'],
        'RDS_Public': result['checking_rds']['Publicly_Accesible']
    }
    errors = {
        'IAM': result['checking_iam']['errors'],
        'EC2': result['checking_ec2']['errors'],
        'S3': result['checking_s3']['errors'],
        'RDS': result['checking_rds']['errors']
    }

    has_findings = any(findings.values())
    has_errors = any(errors.values())



    sns = boto3.client('sns')

    if has_findings or has_errors:
        message = str({
            'findings': findings,
            'errors': errors
        })

        if has_findings and has_errors:
            subject = 'Security Scanner: Findings and Errors'
        elif has_findings:
            subject = 'Security Scanner: Security Findings'
        else:
            subject = 'Security Scanner: Inspection Errors'

        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Message=message,
            Subject=subject
        )
    else:
        print("Security scan completed successfully. No findings or errors.")
    print(result)
    return result
    
if __name__ == "__main__":
    result = lambda_handler({}, None)