import boto3
from botocore.exceptions import ClientError


def check_rds_encryption():
    rds = boto3.client('rds')
    
    try : 
        d_rds = rds.describe_db_instances()
    except ClientError as e :
        print(f"AWS rejected the request: {e}")
        return []
    
    rds_unencrypted = []
    publicly_accessible = []
    
    for enc_rds in d_rds["DBInstances"]:  
                if enc_rds["StorageEncrypted"] == False  :
                    rds_unencrypted.append({
                        'DBInstanceIdentifier' : enc_rds ["DBInstanceIdentifier"],
                        'StorageEncrypted' : enc_rds ['StorageEncrypted']
                    })
                     
                    
                if enc_rds["PubliclyAccessible"] == True :
                    publicly_accessible.append({
                        'DBInstanceIdentifier' : enc_rds['DBInstanceIdentifier'],
                        'Engine' : enc_rds['Engine'],
                        'PubliclyAccessible' : enc_rds ['PubliclyAccessible']
                        
                    })
            
    result = {
        'RDS_unencrypted' : rds_unencrypted,
        'Publicly_Accesible' : publicly_accessible
        
    }
    
    return result 

if __name__ == "__main__":
    result = check_rds_encryption()
    print(result)
        