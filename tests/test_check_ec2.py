from unittest.mock import patch, MagicMock
from check_ec2 import check_ec2_sg


def test_detects_public_ssh_access():
    fake_ec2 = MagicMock()

    fake_ec2.describe_security_groups.return_value = {
        'SecurityGroups': [
            {
                'GroupId': 'sg-123',
                'GroupName': 'public-ssh',
                'IpPermissions': [
                    {
                        'IpProtocol': 'tcp',
                        'FromPort': 22,
                        'ToPort': 22,
                        'IpRanges': [
                            {'CidrIp': '0.0.0.0/0'}
                        ]
                    }
                ]
            }
        ]
    }

    with patch('check_ec2.boto3.client', return_value=fake_ec2):
        result = check_ec2_sg()

    assert len(result['Security_Group']) == 1
    assert result['Security_Group'][0]['GroupId'] == 'sg-123'
    assert result['Security_Group'][0]['FromPort'] == 22
    assert result['All_Traffic'] == []
    
    
def test_detects_all_traffic_open_to_internet():
    fake_ec2 = MagicMock()

    fake_ec2.describe_security_groups.return_value = {
        'SecurityGroups': [
            {
                'GroupId': 'sg-456',
                'GroupName': 'allow-all',
                'IpPermissions': [
                    {
                        'IpProtocol': '-1',
                        'IpRanges': [
                            {'CidrIp': '0.0.0.0/0'}
                        ]
                    }
                ]
            }
        ]
    }

    with patch('check_ec2.boto3.client', return_value=fake_ec2):
        result = check_ec2_sg()

    assert len(result['All_Traffic']) == 1
    assert result['All_Traffic'][0]['GroupId'] == 'sg-456'
    assert result['All_Traffic'][0]['CidrIp'] == '0.0.0.0/0'
    assert result['Security_Group'] == []