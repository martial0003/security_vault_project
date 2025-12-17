import hashlib


def derive_salt(password: str) -> bytes:
    return hashlib.sha256(password.encode()).digest()[:16]


def derive_key(password: str, salt: bytes) -> bytes:
    return hashlib.pbkdf2_hmac(
        "sha256",
        password.encode(),
        salt,
        200_000,
        dklen=32,
    )
