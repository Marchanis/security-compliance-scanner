from unittest.mock import patch, MagicMock
from check_iam import check_iam_mfa


def test_detects_users_without_mfa():
    fake_iam = MagicMock()

    fake_iam.list_users.return_value = {
        'Users': [
            {
                'UserName': 'sol',
                'UserId': '123',
                'Arn': 'arn:aws:iam::123:user/sol',
                'CreateDate': '2024-01-01'
            },
            {
                'UserName': 'bob',
                'UserId': '456',
                'Arn': 'arn:aws:iam::123:user/bob',
                'CreateDate': '2024-01-01'
            }
        ]
    }

    def fake_mfa(UserName):
        if UserName == 'sol':
            return {'MFADevices': []}

        return {'MFADevices': [{'SerialNumber': 'mfa-device-123'}]}

    fake_iam.list_mfa_devices.side_effect = fake_mfa

    with patch('check_iam.boto3.client', return_value=fake_iam):
        result = check_iam_mfa()

    assert len(result['NO_MFA_Users']) == 1
    assert result['NO_MFA_Users'][0]['UserName'] == 'sol'