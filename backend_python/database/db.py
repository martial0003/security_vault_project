import sqlite3

DB_NAME = "vault.db"


def get_db():
    conn = sqlite3.connect(
        DB_NAME,
        timeout=10,
        check_same_thread=False,
    )
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    return conn


def init_db():
    conn = get_db()
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS vaults (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        salt BLOB UNIQUE
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vault_id INTEGER,
        service TEXT,
        username BLOB,
        password BLOB,
        FOREIGN KEY(vault_id) REFERENCES vaults(id)
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS vault_meta (
        vault_id INTEGER UNIQUE,
        is_real INTEGER DEFAULT 0,
        owner_secret_hash BLOB,
        FOREIGN KEY(vault_id) REFERENCES vaults(id)
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS vault_shadow_map (
        real_vault_id INTEGER,
        fake_vault_id INTEGER,
        FOREIGN KEY(real_vault_id) REFERENCES vaults(id),
        FOREIGN KEY(fake_vault_id) REFERENCES vaults(id)
    )
    """)

    conn.commit()
    conn.close()
