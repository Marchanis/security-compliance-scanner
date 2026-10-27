from unittest.mock import patch, MagicMock
from check_s3 import check_public_buckets


def test_flags_only_public_bucket():
    # ARRANGE: build the fake AWS
    fake_s3 = MagicMock()
    fake_s3.list_buckets.return_value = {
        'Buckets': [
            {'Name': 'bucket-one', 'CreationDate': '2024-01-01', 'BucketArn': 'arn:aws:s3:::bucket-one'},
            {'Name': 'bucket-two', 'CreationDate': '2024-01-01', 'BucketArn': 'arn:aws:s3:::bucket-two'},
        ]
    }

    def fake_status(Bucket):
        return {'PolicyStatus': {'IsPublic': Bucket == 'bucket-one'}}

    fake_s3.get_bucket_policy_status.side_effect = fake_status

    # ACT: run your function, with the fake in place of real AWS
    with patch('check_s3.boto3.client', return_value=fake_s3):
        result = check_public_buckets()

    # ASSERT: your part

    assert result == {'Public_bucket': [{'Name': 'bucket-one', 'CreationDate': '2024-01-01', 'BucketArn': 'arn:aws:s3:::bucket-one'}]}

    assert len(result['Public_bucket']) == 1