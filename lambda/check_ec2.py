
import boto3
from botocore.exceptions import ClientError


def check_ec2_sg():
    ec2 = boto3.client('ec2')

    try:
        paginator = ec2.get_paginator('describe_security_groups')

        all_sgs = []

        for page in paginator.paginate():
            all_sgs.extend(page['SecurityGroups'])

    except ClientError as e:
        print(f"AWS rejected the request: {e}")
        return {
            'Security_Group': [],
            'All_Traffic': [],
            'errors': [str(e)]
        }

    public_sg = []
    all_traffic = []
    errors = []

    for sg in all_sgs:
        for permission in sg["IpPermissions"]:

            for ip_range in permission.get("IpRanges", []):
                if permission["IpProtocol"] == '-1' and ip_range["CidrIp"] == "0.0.0.0/0":
                    all_traffic.append({
                        'GroupId': sg['GroupId'],
                        'GroupName': sg['GroupName'],
                        'CidrIp': ip_range['CidrIp']
                    })
                    continue

                elif (
                    permission["IpProtocol"] == "tcp"
                    and permission.get("FromPort", -1) <= 22 <= permission.get("ToPort", -1)
                    and ip_range["CidrIp"] == "0.0.0.0/0"
                ):
                    public_sg.append({
                        'GroupId': sg['GroupId'],
                        'FromPort': permission.get('FromPort'),
                        'CidrIp': ip_range['CidrIp'],
                        'GroupName': sg['GroupName']
                    })

            for ip_range6 in permission.get("Ipv6Ranges", []):
                if permission["IpProtocol"] == '-1' and ip_range6["CidrIpv6"] == "::/0":
                    all_traffic.append({
                        'GroupId': sg['GroupId'],
                        'GroupName': sg['GroupName'],
                        'CidrIpv6': ip_range6['CidrIpv6']
                    })
                    continue

                elif (
                    permission["IpProtocol"] == "tcp"
                    and permission.get("FromPort", -1) <= 22 <= permission.get("ToPort", -1)
                    and ip_range6["CidrIpv6"] == "::/0"
                ):
                    public_sg.append({
                        'GroupId': sg['GroupId'],
                        'FromPort': permission.get('FromPort'),
                        'CidrIpv6': ip_range6['CidrIpv6'],
                        'GroupName': sg['GroupName']
                    })

    result = {
        'Security_Group': public_sg,
        'All_Traffic': all_traffic,
        'errors': errors
    }

    return result


if __name__ == "__main__":
    result = check_ec2_sg()
    print(result)
