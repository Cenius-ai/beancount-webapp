## Authentication module — password hashing, session signing, and HTML escaping for BeanCount.

import bcrypt
import std/[sha1, base64, strutils]
import db_connector/db_sqlite
import database

# ---------------------------------------------------------------------------
# Password hashing
# ---------------------------------------------------------------------------

proc hashPassword*(password: string): string =
  ## Hash a plaintext password using bcrypt.
  let salt = genSalt(10)
  result = hash(password, salt)

proc verifyPassword*(password, storedHash: string): bool =
  ## Verify a plaintext password against a stored bcrypt hash.
  ## The stored hash contains the salt in its prefix ($2a$10$...).
  if storedHash.len < 29:
    return false
  let salt = storedHash[0..28]
  let newHash = hash(password, salt)
  result = compare(newHash, storedHash)

# ---------------------------------------------------------------------------
# HTML escaping — prevents stored/reflected XSS
# ---------------------------------------------------------------------------

proc htmlEscape*(s: string): string =
  ## Encode < > & " ' as HTML entities so user data is safe in HTML body context.
  result = newStringOfCap(s.len)
  for c in s:
    case c
    of '&': result.add("&amp;")
    of '<': result.add("&lt;")
    of '>': result.add("&gt;")
    of '"': result.add("&quot;")
    of '\'': result.add("&#39;")
    else:   result.add(c)

# ---------------------------------------------------------------------------
# HMAC-SHA1 — lightweight signing without extra dependencies
# ---------------------------------------------------------------------------

proc hmacSha1(key, message: string): string =
  ## Compute HMAC-SHA1(key, message) and return hex digest.
  const blockSize = 64
  var k = key

  # If key is longer than block size, hash it first
  if k.len > blockSize:
    k = $secureHash(k)

  # Pad key to block size with zeros
  if k.len < blockSize:
    var padded = newString(blockSize)
    copyMem(padded[0].addr, k[0].addr, k.len)
    for i in k.len ..< blockSize:
      padded[i] = '\0'
    k = padded

  # Inner and outer padded keys
  var iPad = newString(blockSize)
  var oPad = newString(blockSize)
  for i in 0 ..< blockSize:
    iPad[i] = chr(ord(k[i]) xor 0x36)
    oPad[i] = chr(ord(k[i]) xor 0x5c)

  let innerHash = $secureHash(iPad & message)
  result = $secureHash(oPad & innerHash)

# ---------------------------------------------------------------------------
# Signed session tokens
# ---------------------------------------------------------------------------

proc signSession*(userId: int64, secret: string): string =
  ## Create a signed session token: base64(userId):hex_hmac
  let payload = encode($userId)
  let mac = hmacSha1(secret, payload)
  result = payload & ":" & mac

proc verifySession*(token: string, secret: string): int64 =
  ## Verify a signed session token and return the user ID, or -1 if invalid.
  let parts = token.split(':', maxsplit = 1)
  if parts.len != 2:
    return -1

  let payload = parts[0]
  let expectedMac = hmacSha1(secret, payload)
  let providedMac = parts[1]

  # Constant-time comparison to prevent timing attacks
  if expectedMac.len != providedMac.len:
    return -1
  var diff = 0
  for i in 0 ..< expectedMac.len:
    diff = diff or (ord(expectedMac[i]) xor ord(providedMac[i]))
  if diff != 0:
    return -1

  # Decode the payload
  try:
    let userIdStr = decode(payload)
    result = parseInt(userIdStr).int64
  except:
    result = -1

# ---------------------------------------------------------------------------
# User lookups
# ---------------------------------------------------------------------------

proc findUserByEmail*(email: string): Row =
  ## Return the user row for the given email, or a row with empty strings if not found.
  result = db.getRow(
    sql"SELECT id, email, password_hash FROM users WHERE email = ?",
    email
  )

proc findUserById*(userId: int64): Row =
  result = db.getRow(
    sql"SELECT id, email FROM users WHERE id = ?",
    userId
  )
