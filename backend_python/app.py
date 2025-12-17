import hashlib
import time
import uuid
from typing import Dict, Tuple

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from database.db import init_db, get_db
from vault.vault_manager import open_vault


# -------------------------------------------------------------------
# Initialisation
# -------------------------------------------------------------------

app = FastAPI()
init_db()

SESSION_TTL_SECONDS = 60 * 30  # 30 minutes

# session_id -> (vault_id, fernet, created_at)
SESSIONS: Dict[str, Tuple[int, object, float]] = {}


# -------------------------------------------------------------------
# Gestion des sessions
# -------------------------------------------------------------------

def cleanup_sessions():
    now = time.time()
    expired = [
        sid for sid, (_, __, created_at) in SESSIONS.items()
        if now - created_at > SESSION_TTL_SECONDS
    ]
    for sid in expired:
        SESSIONS.pop(sid, None)


def get_fernet_from_session(session_id: str, vault_id: int):
    cleanup_sessions()

    if session_id not in SESSIONS:
        raise HTTPException(status_code=401, detail="invalid_session")

    session_vault_id, fernet, _ = SESSIONS[session_id]

    if session_vault_id != vault_id:
        raise HTTPException(status_code=403, detail="vault_mismatch")

    return fernet


# -------------------------------------------------------------------
# Modèles Pydantic
# -------------------------------------------------------------------

class LoginRequest(BaseModel):
    password: str


class EntryCreate(BaseModel):
    vault_id: int
    session_id: str
    service: str
    username: str
    password: str


class EntryRead(BaseModel):
    vault_id: int
    session_id: str
    service: str


class EntryDelete(BaseModel):
    vault_id: int
    session_id: str
    service: str


class OwnerSecretSet(BaseModel):
    vault_id: int
    session_id: str
    owner_secret: str


class OwnerSecretVerify(BaseModel):
    vault_id: int
    session_id: str
    owner_secret: str


# -------------------------------------------------------------------
# Routes principales
# -------------------------------------------------------------------

@app.post("/login")
def login(data: LoginRequest):
    vault_id, fernet = open_vault(data.password)

    session_id = str(uuid.uuid4())
    SESSIONS[session_id] = (vault_id, fernet, time.time())

    return {
        "vault_id": vault_id,
        "session_id": session_id,
    }


@app.get("/entries/{vault_id}")
def list_entries(vault_id: int, session_id: str):
    _ = get_fernet_from_session(session_id, vault_id)

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        "SELECT service FROM entries WHERE vault_id = ?",
        (vault_id,),
    )
    rows = cur.fetchall()
    conn.close()

    return {"entries": [row[0] for row in rows]}


@app.post("/entries")
def add_entry(entry: EntryCreate):
    fernet = get_fernet_from_session(entry.session_id, entry.vault_id)

    enc_user = fernet.encrypt(entry.username.encode())
    enc_pass = fernet.encrypt(entry.password.encode())

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        """
        INSERT INTO entries (vault_id, service, username, password)
        VALUES (?, ?, ?, ?)
        """,
        (entry.vault_id, entry.service, enc_user, enc_pass),
    )

    conn.commit()
    conn.close()
    return {"status": "added"}


@app.post("/entry/read")
def read_entry(data: EntryRead):
    fernet = get_fernet_from_session(data.session_id, data.vault_id)

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        """
        SELECT username, password
        FROM entries
        WHERE vault_id = ? AND service = ?
        """,
        (data.vault_id, data.service),
    )
    row = cur.fetchone()
    conn.close()

    if not row:
        raise HTTPException(status_code=404, detail="entry_not_found")

    return {
        "username": fernet.decrypt(row[0]).decode(),
        "password": fernet.decrypt(row[1]).decode(),
    }


@app.post("/entry/delete")
def delete_entry(data: EntryDelete):
    _ = get_fernet_from_session(data.session_id, data.vault_id)

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        """
        DELETE FROM entries
        WHERE vault_id = ? AND service = ?
        """,
        (data.vault_id, data.service),
    )

    conn.commit()
    conn.close()
    return {"status": "deleted"}


# -------------------------------------------------------------------
# OWNER — Propriétaire du coffre réel
# -------------------------------------------------------------------

@app.post("/vault/set_owner_secret")
def set_owner_secret(data: OwnerSecretSet):
    """
    Définit un secret propriétaire UNIQUEMENT pour le coffre réel.
    Dans un coffre leurre, l'écriture n'a aucun effet utile.
    """
    fernet = get_fernet_from_session(data.session_id, data.vault_id)

    secret_hash = hashlib.sha256(
        data.owner_secret.encode()
    ).hexdigest().encode()

    encrypted_hash = fernet.encrypt(secret_hash)

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        """
        UPDATE vault_meta
        SET owner_secret_hash = ?
        WHERE vault_id = ?
        """,
        (encrypted_hash, data.vault_id),
    )

    conn.commit()
    conn.close()
    return {"status": "owner_secret_set"}


@app.post("/vault/verify")
def verify_vault(data: OwnerSecretVerify):
    """
    Permet de prouver si le coffre est réel.
    """
    fernet = get_fernet_from_session(data.session_id, data.vault_id)

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        """
        SELECT owner_secret_hash
        FROM vault_meta
        WHERE vault_id = ?
        """,
        (data.vault_id,),
    )
    row = cur.fetchone()
    conn.close()

    if not row or row[0] is None:
        return {"is_real": False}

    stored_hash = fernet.decrypt(row[0]).decode()
    input_hash = hashlib.sha256(
        data.owner_secret.encode()
    ).hexdigest()

    return {"is_real": stored_hash == input_hash}
