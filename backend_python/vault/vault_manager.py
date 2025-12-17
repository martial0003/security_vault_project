from crypto.kdf import derive_key, derive_salt
from crypto.cipher import build_fernet
from database.db import get_db
from vault.fake_mirror import mirror_entry


def open_vault(password: str):
    salt = derive_salt(password)
    key = derive_key(password, salt)
    fernet = build_fernet(key)

    conn = get_db()
    cur = conn.cursor()

    # 1️⃣ Le coffre existe-t-il déjà ?
    cur.execute(
        "SELECT id FROM vaults WHERE salt = ?",
        (salt,),
    )
    row = cur.fetchone()

    if row:
        vault_id = row[0]
        conn.close()
        return vault_id, fernet

    # 2️⃣ Création du coffre
    cur.execute(
        "INSERT INTO vaults (salt) VALUES (?)",
        (salt,),
    )
    vault_id = cur.lastrowid

    # 3️⃣ Existe-t-il déjà un coffre réel ?
    cur.execute(
        "SELECT vault_id FROM vault_meta WHERE is_real = 1",
    )
    real_row = cur.fetchone()

    if real_row is None:
        # PREMIER COFFRE → RÉEL
        cur.execute(
            """
            INSERT INTO vault_meta (vault_id, is_real)
            VALUES (?, 1)
            """,
            (vault_id,),
        )
    else:
        # COFFRE LEURRE
        real_vault_id = real_row[0]

        cur.execute(
            """
            INSERT INTO vault_shadow_map (real_vault_id, fake_vault_id)
            VALUES (?, ?)
            """,
            (real_vault_id, vault_id),
        )

        # Copier uniquement la STRUCTURE (services)
        cur.execute(
            "SELECT DISTINCT service FROM entries WHERE vault_id = ?",
            (real_vault_id,),
        )
        services = [row[0] for row in cur.fetchall()]

        for service in services:
            fake = mirror_entry(
                service=service,
                username=f"user_{service.lower()}",
            )

            cur.execute(
                """
                INSERT INTO entries
                (vault_id, service, username, password)
                VALUES (?, ?, ?, ?)
                """,
                (
                    vault_id,
                    fake["service"],
                    fernet.encrypt(fake["username"].encode()),
                    fernet.encrypt(fake["password"].encode()),
                ),
            )

    conn.commit()
    conn.close()
    return vault_id, fernet
