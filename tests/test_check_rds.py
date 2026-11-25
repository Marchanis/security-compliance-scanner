
from unittest.mock import patch, MagicMock
from check_rds import check_rds_encryption


def test_detects_unencrypted_and_public_rds():
    fake_rds = MagicMock()

    fake_rds.get_paginator.return_value.paginate.return_value = [{
        "DBInstances": [
            {
                "DBInstanceIdentifier": "database-one",
                "StorageEncrypted": False,
                "PubliclyAccessible": True,
                "Engine": "mysql"
            },
            {
                "DBInstanceIdentifier": "database-two",
                "StorageEncrypted": True,
                "PubliclyAccessible": False,
                "Engine": "postgres"
            }
        ]
    }]

    with patch("check_rds.boto3.client", return_value=fake_rds):
        result = check_rds_encryption()

    assert len(result["RDS_unencrypted"]) == 1
    assert result["RDS_unencrypted"][0]["DBInstanceIdentifier"] == "database-one"

    assert len(result["Publicly_Accesible"]) == 1
    assert result["Publicly_Accesible"][0]["DBInstanceIdentifier"] == "database-one"


def test_unencrypted_and_public_rds_on_every_page():
    fake_rds = MagicMock()

    fake_rds.get_paginator.return_value.paginate.return_value = [
        {
            "DBInstances": [
                {
                    "DBInstanceIdentifier": "database-one",
                    "StorageEncrypted": False,
                    "PubliclyAccessible": True,
                    "Engine": "mysql"
                }
            ]
        },
        {
            "DBInstances": [
                {
                    "DBInstanceIdentifier": "database-two",
                    "StorageEncrypted": False,
                    "PubliclyAccessible": False,
                    "Engine": "postgres"
                },
                {
                    "DBInstanceIdentifier": "database-three",
                    "StorageEncrypted": True,
                    "PubliclyAccessible": True,
                    "Engine": "mysql"
                }
            ]
        }
    ]

    with patch("check_rds.boto3.client", return_value=fake_rds):
        result = check_rds_encryption()

    assert len(result["RDS_unencrypted"]) == 2
    assert result["RDS_unencrypted"][0]["DBInstanceIdentifier"] == "database-one"
    assert result["RDS_unencrypted"][1]["DBInstanceIdentifier"] == "database-two"

    assert len(result["Publicly_Accesible"]) == 2
    assert result["Publicly_Accesible"][0]["DBInstanceIdentifier"] == "database-one"
    assert result["Publicly_Accesible"][1]["DBInstanceIdentifier"] == "database-three"

    fake_rds.get_paginator.assert_called_once_with("describe_db_instances")
