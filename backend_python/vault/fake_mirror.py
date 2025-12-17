import random
import string


def mutate_username(username: str) -> str:
    if "@" in username:
        name, domain = username.split("@", 1)
        return f"{name}.backup@{domain}"

    return f"{username}_{random.randint(10, 99)}"


def generate_fake_password(length: int) -> str:
    chars = string.ascii_letters + string.digits + "!@#$%"
    return "".join(
        random.choice(chars)
        for _ in range(length)
    )


def mirror_entry(service: str, username: str) -> dict:
    fake_username = mutate_username(username)
    fake_password = generate_fake_password(
        max(len(username), 10)
    )

    return {
        "service": service,
        "username": fake_username,
        "password": fake_password,
    }
