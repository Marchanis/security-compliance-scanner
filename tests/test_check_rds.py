from unittest.mock import patch, MagicMock
from check_rds import check_rds_encryption


def test_detects_unencrypted_and_public_rds():
    fake_rds = MagicMock()

    fake_rds.describe_db_instances.return_value = {
        'DBInstances': [
            {
                'DBInstanceIdentifier': 'database-one',
                'StorageEncrypted': False,
                'PubliclyAccessible': True,
                'Engine': 'mysql'
            },
            {
                'DBInstanceIdentifier': 'database-two',
                'StorageEncrypted': True,
                'PubliclyAccessible': False,
                'Engine': 'postgres'
            }
        ]
    }

    with patch('check_rds.boto3.client', return_value=fake_rds):
        result = check_rds_encryption()

    assert len(result['RDS_unencrypted']) == 1
    assert result['RDS_unencrypted'][0]['DBInstanceIdentifier'] == 'database-one'

    assert len(result['Publicly_Accesible']) == 1
    assert result['Publicly_Accesible'][0]['DBInstanceIdentifier'] == 'database-one'