from unittest.mock import patch, MagicMock
from check_s3 import check_public_buckets
from botocore.exceptions import ClientError


def test_flags_only_public_bucket():
    fake_s3 = MagicMock()
    fake_s3.list_buckets.return_value = {
        'Buckets': [
            {'Name': 'bucket-one', 'CreationDate': '2024-01-01'},
            {'Name': 'bucket-two', 'CreationDate': '2024-01-01'},
        ]
    }

    def fake_status(Bucket):
        return {'PolicyStatus': {'IsPublic': Bucket == 'bucket-one'}}

    fake_s3.get_bucket_policy_status.side_effect = fake_status

    with patch('check_s3.boto3.client', return_value=fake_s3):
        result = check_public_buckets()


    assert result == {'Public_bucket':  [{'Name': 'bucket-one', 'CreationDate': '2024-01-01', 'BucketArn': 'arn:aws:s3:::bucket-one'}],
                      'errors': []}

    assert len(result['Public_bucket']) == 1
    


def test_list_buckets_error():
    fake_s3 = MagicMock()

    fake_s3.list_buckets.side_effect = ClientError(
        {
            'Error': {
                'Code': 'AccessDenied',
                'Message': 'Access denied'
            }
        },
        'ListBuckets'
    )

    with patch('check_s3.boto3.client', return_value=fake_s3):
        result = check_public_buckets()

    assert result['Public_bucket'] == []
    assert 'errors' in result
    assert 'AccessDenied' in result['errors'][0]
    
    
def test_bucket_policy_error():
    fake_s3 = MagicMock()

    fake_s3.list_buckets.return_value = {
        'Buckets': [
            {'Name': 'bucket-one', 'CreationDate': '2024-01-01'},
            {'Name': 'bucket-two', 'CreationDate': '2024-01-01'}
        ]
    }

    def fake_status(Bucket):
        if Bucket == 'bucket-two':
            raise ClientError(
                {
                    'Error': {
                        'Code': 'AccessDenied',
                        'Message': 'Access denied'
                    }
                },
                'GetBucketPolicyStatus'
            )

        return {'PolicyStatus': {'IsPublic': True}}

    fake_s3.get_bucket_policy_status.side_effect = fake_status

    with patch('check_s3.boto3.client', return_value=fake_s3):
        result = check_public_buckets()

    assert len(result['Public_bucket']) == 1
    assert result['Public_bucket'][0]['Name'] == 'bucket-one'