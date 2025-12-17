import random
import string


FAKE_SERVICES = [
    "Google",
    "Facebook",
    "Amazon",
    "LinkedIn",
    "Instagram",
    "Microsoft",
]


def random_password(length=10):
    chars = string.ascii_letters + string.digits + "!@#$%"
    return "".join(
        random.choice(chars)
        for _ in range(length)
    )


def generate_fake_entries():
    entries = []

    for service in FAKE_SERVICES:
        username = f"user_{random.randint(1000, 9999)}"
        password = random_password()

        entries.append(
            {
                "service": service,
                "username": username,
                "password": password,
            }
        )

    return entries
