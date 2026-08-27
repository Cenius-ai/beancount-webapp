## Database module — SQLite connection, schema, and query helpers for BeanCount.

import db_connector/db_sqlite
import std/[os]

var db*: DbConn

const DbPath = "beancount.db"

proc createSchema*()

proc initDatabase*() =
  ## Open (or create) the SQLite database and set up the schema.
  let exists = fileExists(DbPath)
  db = open(DbPath, "", "", "")
  # Enable WAL mode for better concurrency
  db.exec(sql"PRAGMA journal_mode=WAL")
  db.exec(sql"PRAGMA foreign_keys=ON")

  if not exists:
    createSchema()

proc createSchema*() =
  ## Create all tables and indexes if they don't exist.
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS users (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      email         TEXT    UNIQUE NOT NULL,
      password_hash TEXT    NOT NULL
    )
  """)

  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS brews (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      method     TEXT    NOT NULL,
      grind      TEXT    NOT NULL,
      rating     INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
      notes      TEXT    DEFAULT '',
      created_at TEXT    DEFAULT (datetime('now'))
    )
  """)

  db.exec(sql"""
    CREATE INDEX IF NOT EXISTS ix_brews_user_id ON brews(user_id)
  """)
  db.exec(sql"""
    CREATE INDEX IF NOT EXISTS ix_brews_created ON brews(created_at)
  """)

  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS beans (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name     TEXT    NOT NULL,
      origin   TEXT    DEFAULT '',
      roast    TEXT    DEFAULT '',
      quantity INTEGER DEFAULT 0
    )
  """)

  db.exec(sql"""
    CREATE INDEX IF NOT EXISTS ix_beans_user_id ON beans(user_id)
  """)

proc closeDatabase*() =
  db.close()
