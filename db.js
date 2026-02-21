const Database = require('better-sqlite3');
const path = require('path');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'wood.db');

const db = new Database(DB_PATH);

db.exec(`
  CREATE TABLE IF NOT EXISTS wood (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    species   TEXT    NOT NULL,
    width     REAL,
    thickness REAL,
    length    REAL,
    quantity  INTEGER NOT NULL DEFAULT 1,
    condition TEXT,
    source    TEXT,
    notes     TEXT,
    photo     TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  )
`);

module.exports = db;
