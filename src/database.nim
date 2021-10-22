import tiny_sqlite
import std / [options, times]

import dbUtils

const migrations = [
  """
  CREATE TABLE schema_version (
    version INTEGER NOT NULL
  );
  CREATE TABLE url (
    id INTEGER PRIMARY KEY,
    token TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    url TEXT,
    created DATE,
    expires DATE
  );
  CREATE UNIQUE INDEX idx_url_token ON url(token);
  """
]
const latestVersion = migrations.len

proc Migrate*(db: DbConn): bool {.raises: [].} =
  var currentVersion : int
  try:
    currentVersion = db.value("SELECT version FROM schema_version;").get().fromDbValue(int)
  except SqliteError:
    discard
  if currentVersion != latestVersion:
    try:
      db.exec("BEGIN")
      for v in currentVersion..<latestVersion:
        db.execScript(migrations[v])
      db.exec("DELETE FROM schema_version;")
      db.exec("INSERT INTO schema_version (version) VALUES (?);", latestVersion)
      db.exec("COMMIT;")
    except:
      let msg = getCurrentExceptionMsg()
      echo msg
      try:
        db.exec("ROLLBACK")
      except SqliteError:
        discard
      return false
  return true

type ShortUrl* = object
  ID*: int
  Token*: string
  Title*: string
  Url*: string
  Created*: DateTime
  Expires*: DateTime

proc AddUrl*(db: DbConn, url: ShortUrl) {.raises: [SqliteError].} =
  let stmt = db.stmt("""
    INSERT INTO url(token, title, url, created, expires)
    VALUES (?, ?, ?, ?, ?);
  """)
  stmt.exec(url.Token, url.Title, url.Url, url.Created, $url.Expires)

proc GetUrl*(db: DbConn, token: string): ref ShortUrl {.raises: [SqliteError].} =
  let stmt = db.stmt("SELECT id, title, url, created, expires FROM url WHERE token = ?")
  for row in stmt.iterate(token):
    new(result)
    result.ID = row[0].fromDbValue(int)
    result.Token = token
    result.Title = row[1].fromDbValue(string)
    result.Url = row[2].fromDbValue(string)
    result.Created = row[3].fromDbValue(DateTime)
    result.Expires = row[4].fromDbValue(DateTime)

proc CleanExpired*(db: DbConn) {.raises: [].} =
  try:
    let stmt = db.stmt("DELETE FROM url WHERE expires < ?")
    stmt.exec(times.now())
  except:
    discard
