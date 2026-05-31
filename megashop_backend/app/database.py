import sqlite3
from pathlib import Path

DB_PATH = Path("megashop.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn
    conn.execute("""
CREATE TABLE IF NOT EXISTS users (
    firebase_uid TEXT PRIMARY KEY,
    email TEXT,
    username TEXT,
    bio TEXT,
    profile_photo TEXT
)
""")

def init_db():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        description TEXT NOT NULL,
        image TEXT NOT NULL
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        caption TEXT NOT NULL,
        image TEXT NOT NULL
    )
    """)
    

    cur.execute("""
    CREATE TABLE IF NOT EXISTS reels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        caption TEXT NOT NULL,
        video TEXT NOT NULL
    )
    """)

    conn.commit()
    conn.close()

init_db()