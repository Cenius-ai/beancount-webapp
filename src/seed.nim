## Seed module — idempotent demo data for BeanCount.

import std/[logging, strutils]
import db_connector/db_sqlite
import database, auth

const demoEmail = "cenius@cenius.ai"
const demoPassword = "cenius"

proc seedDemoData*() =
  ## Seed the demo user and sample brews, idempotently.
  ## If the demo user already exists, do nothing.

  let existing = findUserByEmail(demoEmail)
  if existing.len > 0 and existing[0] != "":
    info "Demo user already exists — skipping seed."
    return

  info "Seeding demo data..."

  # Create demo user
  let pwHash = hashPassword(demoPassword)
  db.exec(
    sql"INSERT INTO users (email, password_hash) VALUES (?, ?)",
    demoEmail, pwHash
  )

  let userRow = findUserByEmail(demoEmail)
  let userId = parseInt(userRow[0])

  # Insert 10 sample brews with realistic coffee-brewing data
  # created_at spaced out over the last 10 days
  type BrewData = tuple[brewMethod, grind: string, rating: int, notes: string]
  let brews: array[10, BrewData] = [
    ("V60",          "Medium-Fine",    4, "Bright and clean with floral notes"),
    ("French Press", "Coarse",         3, "Full-bodied but slightly muddy"),
    ("Aeropress",    "Fine",           5, "Perfect extraction — sweet and balanced"),
    ("Chemex",       "Medium-Coarse",  4, "Clean cup, subtle berry undertones"),
    ("Espresso",     "Fine",           4, "Rich crema, chocolate-forward"),
    ("V60",          "Medium",         3, "A bit over-extracted — try coarser next time"),
    ("Kalita Wave",  "Medium",         5, "Consistent drawdown, caramel sweetness"),
    ("French Press", "Coarse",         4, "Let it steep 4min — smooth and rich"),
    ("Aeropress",    "Medium-Fine",    4, "Inverted method, 2min steep"),
    ("Chemex",       "Medium-Coarse",  5, "Ethiopian beans shine through"),
  ]

  for i, b in brews:
    let offset = -(brews.len - i)
    db.exec(
      sql"""INSERT INTO brews (user_id, method, grind, rating, notes, created_at)
            VALUES (?, ?, ?, ?, ?, datetime('now', ? || ' days'))""",
      userId, b.brewMethod, b.grind, b.rating, b.notes, $offset
    )

  # Insert some sample beans too
  type BeanData = tuple[name, origin, roast: string, qty: int]
  let beans: array[5, BeanData] = [
    ("Ethiopia Yirgacheffe", "Ethiopia",  "Light",  250),
    ("Colombia Huila",       "Colombia",  "Medium", 340),
    ("Brazil Cerrado",       "Brazil",    "Dark",   500),
    ("Kenya AA",             "Kenya",     "Light",  200),
    ("Guatemala Antigua",    "Guatemala", "Medium", 300),
  ]

  for (name, origin, roast, qty) in beans:
    db.exec(
      sql"INSERT INTO beans (user_id, name, origin, roast, quantity) VALUES (?, ?, ?, ?, ?)",
      userId, name, origin, roast, qty
    )

  info "Seed complete: demo user + 10 brews + 5 beans created."

when isMainModule:
  # Allow running standalone: `nim r src/seed.nim`
  initDatabase()
  seedDemoData()
  closeDatabase()
  echo "Seed finished."
