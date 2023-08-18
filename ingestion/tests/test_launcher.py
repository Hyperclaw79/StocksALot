# pylint: skip-file
import os
import pytest
from ingestion.launcher import fetch_password

os.environ |= {
    'TEST1_PASSWORD': 'test',
    'TEST2_PASSWORD_FILE': os.path.join(
        os.path.dirname(__file__), 'data', 'PASSWORD'
    )
}


@pytest.mark.parametrize('pwd_name, default, expected', [
    ('TEST1_PASSWORD', None, 'test'),
    ('TEST1_PASSWORD', 'default', 'test'),
    ('TEST2_PASSWORD', None, 'test'),
    ('TEST2_PASSWORD', 'default', 'test'),
    ('TEST3_PASSWORD', None, None),
    ('TEST3_PASSWORD', 'default', 'default')
])
def test_fetch_password(pwd_name, default, expected):
    assert fetch_password(pwd_name, default) == expected
