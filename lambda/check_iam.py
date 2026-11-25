import boto3
from botocore.exceptions import ClientError


def check_iam_mfa():
    iam = boto3.client('iam')

    try:
        paginator = iam.get_paginator('list_users')

        all_users = []

        for page in paginator.paginate():
            all_users.extend(page['Users'])

    except ClientError as e:
        print(f"AWS rejected the request: {e}")
        return {
            'NO_MFA_Users': [],
            'errors': [str(e)]
        }

    no_mfa_user = []
    errors = []

    for user in all_users:
        try:
            no_mfa_users = iam.list_mfa_devices(UserName=user['UserName'])
            if not no_mfa_users['MFADevices']:
                no_mfa_user.append({
                    'UserName': user['UserName'],
                    'UserId': user['UserId'],
                    'Arn': user['Arn'],
                    'CreateDate': user['CreateDate']
                })
        except ClientError as e:
            error = f"Username {user['UserName']} failed: {e}"
            errors.append(error)
            print(error)

    result = {
        'NO_MFA_Users': no_mfa_user,
        'errors': errors
    }
    return result


if __name__ == "__main__":
    result = check_iam_mfa()
    print(result)