import boto3
from botocore.exceptions import ClientError

def check_ec2_sg():
    ec2 = boto3.client('ec2')
    
    try :
        d_ins = ec2.describe_security_groups()                                                                      
    except ClientError as e :
        print(f"AWS rejected the request: {e}")
        return []
            
    
    public_sg = []
    all_traffic = []

    
    for sg in d_ins ['SecurityGroups']:
        for permission in sg["IpPermissions"]:
            for ip_range in permission["IpRanges"]:
                if permission["IpProtocol"] == '-1' and  ip_range["CidrIp"] == "0.0.0.0/0":
                    all_traffic.append({
                        'GroupId':sg['GroupId'],
                        'GroupName': sg['GroupName'],
                        'CidrIp': ip_range['CidrIp']

                    })
                    continue
                    
                elif permission["IpProtocol"] != '-1' and  permission["FromPort"] == 22 and ip_range["CidrIp"] == "0.0.0.0/0" :
                    public_sg.append({
                            'GroupId': sg['GroupId'],
                            'FromPort': permission['FromPort'],
                            'CidrIp': ip_range['CidrIp'],
                            'GroupName': sg['GroupName']

                                                    
                        })
    result = {
        'Security_Group': public_sg,
        'All_Traffic': all_traffic
    }
    
    return result
                    

if __name__ == "__main__":
    result = check_ec2_sg()
    print(result)