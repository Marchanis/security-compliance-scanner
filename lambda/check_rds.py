
import boto3
from botocore.exceptions import ClientError


def check_rds_encryption():
    rds = boto3.client("rds")

    rds_unencrypted = []
    publicly_accessible = []
    errors = []

    try:
        paginator = rds.get_paginator("describe_db_instances")

        for page in paginator.paginate():
            for instance in page.get("DBInstances", []):

                if not instance.get("StorageEncrypted", False):
                    rds_unencrypted.append({
                        "DBInstanceIdentifier": instance["DBInstanceIdentifier"],
                        "StorageEncrypted": instance.get("StorageEncrypted", False)
                    })

                if instance.get("PubliclyAccessible", False):
                    publicly_accessible.append({
                        "DBInstanceIdentifier": instance["DBInstanceIdentifier"],
                        "Engine": instance.get("Engine"),
                        "PubliclyAccessible": instance.get("PubliclyAccessible", False)
                    })

    except ClientError as e:
        print(f"AWS rejected the request: {e}")
        errors.append(str(e))

    except Exception as e:
        print(f"Unexpected error while scanning RDS: {e}")
        errors.append(str(e))

    return {
        "RDS_unencrypted": rds_unencrypted,
        "Publicly_Accesible": publicly_accessible,
        "errors": errors
    }


if __name__ == "__main__":
    result = check_rds_encryption()
    print(result)
