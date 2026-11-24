from unittest.mock import patch, MagicMock
from lambda_function import lambda_handler


def test_lambda_handler_runs_checks_and_publishes_sns():

    with patch('lambda_function.check_iam.check_iam_mfa') as iam_mock, \
         patch('lambda_function.check_ec2.check_ec2_sg') as ec2_mock, \
         patch('lambda_function.check_s3.check_public_buckets') as s3_mock, \
         patch('lambda_function.check_rds.check_rds_encryption') as rds_mock, \
         patch('lambda_function.boto3.client') as boto_mock, \
         patch.dict('os.environ', {'SNS_TOPIC_ARN': 'arn:aws:sns:us-east-1:123:security-alerts'}):

        iam_mock.return_value = {'NO_MFA_Users': [], 'errors': []}
        ec2_mock.return_value = {'Security_Group': [], 'All_Traffic': [] , 'errors': []}
        s3_mock.return_value = {
            'Public_bucket': [{'Name': 'test-bucket', 'CreationDate': '2024-01-01', 'BucketArn': 'arn:aws:s3:::test-bucket'}],
            'errors': []
        }
        rds_mock.return_value = {'RDS_unencrypted': [], 'Publicly_Accesible': [], 'errors': []}

        fake_sns = MagicMock()
        boto_mock.return_value = fake_sns

        result = lambda_handler({}, None)

        assert 'checking_iam' in result
        assert 'checking_ec2' in result
        assert 'checking_s3' in result
        assert 'checking_rds' in result

        iam_mock.assert_called_once()
        ec2_mock.assert_called_once()
        s3_mock.assert_called_once()
        rds_mock.assert_called_once()

        fake_sns.publish.assert_called_once()