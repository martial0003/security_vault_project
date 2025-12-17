import base64
from cryptography.fernet import Fernet


def build_fernet(key: bytes) -> Fernet:
    return Fernet(base64.urlsafe_b64encode(key))
