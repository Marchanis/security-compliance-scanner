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
    



    sns = boto3.client('sns')
    
    messgae = str(result)
    
    sns.publish(
        TopicArn = os.environ['SNS_TOPIC_ARN'],
        Message = messgae,
        Subject = 'Security compliance scanner'
    )
    
    print(result)
    return result


    
    
    
if __name__ == "__main__":
    result = lambda_handler({}, None)