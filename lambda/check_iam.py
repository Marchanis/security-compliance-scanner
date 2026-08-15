import boto3
from botocore.exceptions  import ClientError


def check_iam_mfa():
    iam = boto3.client('iam')
    
    try :
        u_iam = iam.list_users()
    except ClientError as e :
        print(f" AWS rejected the request: {e}")
        return []
    
    
    no_mfauser = []


    for user in u_iam['Users']:
        try : 
            no_mfa_users= iam.list_mfa_devices(UserName=user['UserName'])
            if not no_mfa_users['MFADevices']:
                no_mfauser.append({
                    'UserName' : user ['UserName'],
                    'UserId' : user ['UserId'],
                    'Arn' : user ['Arn'],
                    'CreateDate' : user ['CreateDate']

                })
        except ClientError as e:
            print (f"Username {user['Name']} failed : {e}")
            

    result = {
        'NO_MFA_Users' : no_mfauser
    }
    return result

    

if __name__ == "__main__":
    result = check_iam_mfa()
    print(result)