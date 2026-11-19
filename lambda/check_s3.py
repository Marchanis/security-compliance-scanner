import boto3
from botocore.exceptions import ClientError


def check_public_buckets():
    s3 = boto3.client('s3')
    
    try : 
        list_b = s3.list_buckets()
    except ClientError as e:
        return {'Public_bucket': [], 'error': str(e)}


    public_bucket = []

    for bucket in list_b ['Buckets']:
        try :
            policy_status = s3.get_bucket_policy_status(Bucket=bucket['Name'])
            if policy_status['PolicyStatus']['IsPublic'] :
                public_bucket.append({
                    'Name': bucket['Name'],
                    'CreationDate': bucket['CreationDate'],
                    'BucketArn': f"arn:aws:s3:::{bucket['Name']}"
            })
        except ClientError as e:
            print(f"Could not check bucket {bucket['Name']}: {e}")
            continue
                
                
    result = {
            'Public_bucket': public_bucket
    }
        
    return result


if __name__ == "__main__":
    result = check_public_buckets()
    print(result)                    
                
            
            