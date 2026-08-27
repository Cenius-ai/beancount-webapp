## BeanCount — Coffee-brew journal web application.
## Main entry point with Jester routes and server-rendered HTML.

import jester
import db_connector/db_sqlite
import std/[strutils, options, os, logging, tables]
import database, auth, seed

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# Per-platform rules: a dev fallback is required so the app boots with zero env.
# install.sh generates a real per-install secret into .env, which overrides this.
const SessionSecretFallback = "b3anc0unt-d3v-s3ss10n-k3y-7f3a1b2c"
const AppName = "BeanCount"
const AppAccent = "#00965e"

proc getSessionSecret(): string =
  result = getEnv("SESSION_SECRET", SessionSecretFallback)

# Re-export htmlEscape locally so all route code can call it
proc h(s: string): string = htmlEscape(s)

# ---------------------------------------------------------------------------
# HTML helpers
# ---------------------------------------------------------------------------

proc page(title: string, bodyContent: string, loggedIn: bool, extraHead: string = ""): string =
  ## Wrap content in the common layout shell.
  let navBar = if loggedIn:
    """<nav class="topbar">
  <a href="/brews" class="logo">BeanCount</a>
  <div class="nav-links">
    <a href="/brews">Brews</a>
    <a href="/beans">Beans</a>
    <a href="/logout">Log out</a>
  </div>
</nav>"""
  else:
    """<nav class="topbar">
  <a href="/login" class="logo">BeanCount</a>
</nav>"""

  result = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>""" & h(title) & """ — BeanCount</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --card:            #fffefc;
      --ring:            #ef6661;
      --muted:           #f4eae7;
      --accent:          #ef6661;
      --border:          #e6dcd8;
      --primary:         #ef6661;
      --on-accent:       #111111;
      --secondary:       #f4eae7;
      --background:      #fff8f4;
      --foreground:      #1c0f0a;
      --on-primary:      #111111;
      --destructive:     #c9302d;
      --on-secondary:    #1c0f0a;
      --on-destructive:  #ffffff;
      --card-foreground: #1c0f0a;
      --muted-foreground:#705f59;
      --radius:          0.5rem;
      --font-display:    'Hanken Grotesk', sans-serif;
      --font-body:       'Hanken Grotesk', sans-serif;
    }
    *, *::before, *::after { box-sizing:border-box; margin:0; padding:0; }
    html { font-size:16px; }
    body {
      font-family: var(--font-body);
      background: var(--background);
      color: var(--foreground);
      line-height: 1.6;
      min-height: 100vh;
    }

    /* ── topbar: flat solid surface ── */
    .topbar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0.75rem 1.5rem;
      background: var(--card);
      border-bottom: 2px solid var(--border);
    }
    .topbar .logo {
      font-family: var(--font-display);
      font-weight: 700;
      font-size: 1.15rem;
      color: var(--accent);
      text-decoration: none;
      letter-spacing: -0.01em;
    }
    .nav-links { display:flex; gap: 1.25rem; }
    .nav-links a {
      font-family: var(--font-body);
      color: var(--muted-foreground);
      text-decoration: none;
      font-weight: 600;
      font-size: 0.875rem;
      transition: color 180ms ease;
    }
    .nav-links a:hover { color: var(--foreground); }

    /* ── container ── */
    .container {
      max-width: 48rem;
      margin: 0 auto;
      padding: 2rem 1.25rem;
    }

    /* ── headings ── */
    h1 {
      font-family: var(--font-display);
      font-size: 1.5rem;
      font-weight: 700;
      margin-bottom: 1.5rem;
      letter-spacing: -0.02em;
      color: var(--foreground);
    }
    h2 {
      font-family: var(--font-display);
      font-size: 1.15rem;
      font-weight: 600;
      margin-bottom: 0.75rem;
    }

    /* ── forms ── */
    .form-group { margin-bottom: 1.25rem; }
    label {
      display:block;
      font-family: var(--font-body);
      font-size:0.85rem;
      font-weight:600;
      color:var(--muted-foreground);
      margin-bottom:0.35rem;
    }
    input, select, textarea {
      width: 100%;
      padding: 0.6rem 0.75rem;
      background: var(--card);
      border: 2px solid var(--border);
      border-radius: var(--radius);
      color: var(--foreground);
      font-family: var(--font-body);
      font-size: 0.95rem;
      transition: border-color 180ms ease;
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--accent);
    }
    textarea { resize: vertical; min-height: 4rem; }

    /* ── buttons: flat solid rectangles, 8px radius, 700 weight ── */
    button, .btn {
      display: inline-block;
      padding: 0.55rem 1.25rem;
      background: var(--primary);
      color: var(--on-primary);
      border: none;
      border-radius: var(--radius);
      font-family: var(--font-body);
      font-weight: 700;
      font-size: 0.875rem;
      cursor: pointer;
      text-decoration: none;
      transition: opacity 180ms ease;
      box-shadow: none;
    }
    button:hover, .btn:hover { opacity: 0.88; }
    .btn-outline {
      background: transparent;
      border: 2px solid var(--border);
      color: var(--foreground);
      font-weight: 600;
    }
    .btn-outline:hover {
      background: var(--secondary);
      opacity: 1;
    }
    .btn-sm { padding: 0.35rem 0.85rem; font-size: 0.8rem; }

    /* ── cards: flat, no shadow, border separation ── */
    .card {
      background: var(--card);
      border: 2px solid var(--border);
      border-radius: var(--radius);
      padding: 1rem 1.25rem;
      margin-bottom: 0.75rem;
      box-shadow: none;
    }
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      margin-bottom: 0.35rem;
    }
    .card-title {
      font-family: var(--font-display);
      font-weight: 700;
      font-size: 1rem;
      color: var(--card-foreground);
    }
    .card-meta { font-family: var(--font-body); font-size: 0.8rem; color: var(--muted-foreground); }
    .card-detail { font-family: var(--font-body); font-size: 0.85rem; color: var(--muted-foreground); margin-top: 0.25rem; }

    /* ── badges ── */
    .badge {
      display: inline-block;
      padding: 0.15rem 0.5rem;
      border-radius: 999px;
      font-family: var(--font-body);
      font-size: 0.75rem;
      font-weight: 700;
      background: var(--secondary);
      color: var(--on-secondary);
    }
    .badge-accent { background: var(--accent); color: var(--on-accent); }

    /* ── star ratings ── */
    .stars { color: var(--accent); letter-spacing: 0.05em; }
    .stars-dim { color: var(--muted-foreground); opacity: 0.4; }

    /* ── pagination ── */
    .pagination {
      display: flex;
      justify-content: center;
      gap: 0.75rem;
      margin-top: 1.5rem;
    }
    .pagination a, .pagination span {
      padding: 0.35rem 0.75rem;
      border: 2px solid var(--border);
      border-radius: var(--radius);
      font-family: var(--font-body);
      font-size: 0.85rem;
      font-weight: 600;
      text-decoration: none;
      color: var(--muted-foreground);
      background: var(--card);
    }
    .pagination a:hover { background: var(--secondary); color: var(--foreground); }
    .pagination .current {
      background: var(--primary);
      color: var(--on-primary);
      border-color: var(--primary);
    }

    /* ── login box ── */
    .login-box {
      max-width: 24rem;
      margin: 4rem auto;
      background: var(--card);
      border: 2px solid var(--border);
      border-radius: var(--radius);
      padding: 2rem;
      box-shadow: none;
    }
    .demo-hint {
      margin-top: 1.5rem;
      padding: 0.75rem 1rem;
      background: var(--secondary);
      border: 2px solid var(--accent);
      border-radius: var(--radius);
      font-family: var(--font-body);
      font-size: 0.82rem;
      color: var(--muted-foreground);
    }
    .demo-hint strong { color: var(--accent); font-weight: 700; }

    /* ── flash messages ── */
    .flash {
      padding: 0.6rem 1rem;
      border-radius: var(--radius);
      margin-bottom: 1rem;
      font-family: var(--font-body);
      font-size: 0.85rem;
      font-weight: 600;
    }
    .flash-error {
      background: #fef2f2;
      border: 2px solid var(--destructive);
      color: var(--destructive);
    }

    /* ── empty state ── */
    .empty-state {
      text-align: center;
      padding: 3rem 1rem;
      color: var(--muted-foreground);
      font-family: var(--font-body);
    }
    .empty-state p { margin-bottom: 1rem; }

    /* ── tables ── */
    table { width:100%; border-collapse:collapse; }
    th, td {
      padding:0.6rem 0.75rem;
      text-align:left;
      border-bottom:2px solid var(--border);
      font-family: var(--font-body);
      font-size:0.9rem;
    }
    th {
      color: var(--muted-foreground);
      font-weight:700;
      font-size:0.8rem;
      text-transform:uppercase;
      letter-spacing:0.03em;
    }
    tr:hover td { background: var(--secondary); }

    @media (max-width: 480px) {
      .container { padding: 1rem 0.75rem; }
      .topbar { padding: 0.6rem 1rem; }
      .card-header { flex-direction: column; }
    }

    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after { transition-duration:0s !important; animation-duration:0s !important; }
    }
  </style>

  """ & extraHead & """
</head>
<body>
  """ & navBar & """
  <main class="container">
    """ & bodyContent & """
  </main>
</body>
</html>"""

proc starsHtml(rating: int, maxStars: int = 5): string =
  result = """<span class="stars">"""
  for i in 1..maxStars:
    if i <= rating: result.add("★")
  result.add("""</span><span class="stars-dim">""")
  for i in rating+1..maxStars:
    result.add("★")
  result.add("</span>")

proc methodLabel(brewMethod: string): string =
  result = """<span class="badge badge-accent">""" & h(brewMethod) & "</span>"

# ---------------------------------------------------------------------------
# Session helpers — extract user ID from signed cookie, or return -1
# ---------------------------------------------------------------------------

proc getSessionUserId(req: Request): int64 =
  ## Extract and verify the user ID from the signed session cookie.
  ## Returns the user ID on success, or -1 if missing/invalid.
  if req.cookies().hasKey("bc_session"):
    let token = req.cookies()["bc_session"]
    if token.len > 0:
      let secret = getSessionSecret()
      result = verifySession(token, secret)
      return
  result = -1

# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

# Startup — must run before Jester routes macro captures settings
# ---------------------------------------------------------------------------

addHandler(newConsoleLogger(fmtStr = "$datetime $appname: $levelname: "))
info "Initializing database..."
initDatabase()
info "Running seed..."
seedDemoData()
info "Starting server..."

let serverPort = Port(parseInt(getEnv("PORT", "5000")))
settings:
  port = serverPort
  bindAddr = "0.0.0.0"
routes:
  get "/":
    let uid = getSessionUserId(request)
    if uid >= 0:
      redirect("/brews")
    else:
      redirect("/login")

  get "/login":
    let flash = if request.cookies().hasKey("bc_flash"):
      let msg = request.cookies()["bc_flash"]
      setCookie("bc_flash", "", expires = "Thu, 01 Jan 1970 00:00:00 GMT", path = "/")
      """<div class="flash flash-error">""" & h(msg) & "</div>"
    else:
      ""

    let body = """
    <div class="login-box">
      <h1 style="text-align:center;">Welcome to BeanCount</h1>
      <p style="text-align:center;color:var(--muted-foreground);margin-bottom:1.5rem;">Log in to your coffee journal</p>
      """ & flash & """
      <form method="post" action="/login">
        <div class="form-group">
          <label for="email">Email</label>
          <input type="email" id="email" name="email" required autofocus>
        </div>
        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" required>
        </div>
        <button type="submit" style="width:100%;">Log in</button>
      </form>
      <div class="demo-hint">
        <strong>Demo:</strong> cenius@cenius.ai / cenius
      </div>
    </div>"""
    resp page("Log in", body, loggedIn = false), "text/html"

  post "/login":
    let email = request.params.getOrDefault("email")
    let password = request.params.getOrDefault("password")

    if email.len == 0 or password.len == 0:
      setCookie("bc_flash", "Email and password are required.", path = "/")
      redirect("/login")

    let user = findUserByEmail(email)
    if user[0] == "":
      setCookie("bc_flash", "Invalid email or password.", path = "/")
      redirect("/login")

    let pwHash = user[2]
    if not verifyPassword(password, pwHash):
      setCookie("bc_flash", "Invalid email or password.", path = "/")
      redirect("/login")

    let userId = parseInt(user[0]).int64
    let secret = getSessionSecret()
    let signedToken = signSession(userId, secret)
    setCookie("bc_session", signedToken, httpOnly = true, sameSite = Lax, path = "/")
    redirect("/brews")

  get "/logout":
    setCookie("bc_session", "", httpOnly = true, sameSite = Lax, path = "/",
              expires = "Thu, 01 Jan 1970 00:00:00 GMT")
    redirect("/login")

  get "/brews":
    let userId = getSessionUserId(request)
    if userId < 0:
      redirect("/login")
    else:
      let page = try: parseInt(request.params.getOrDefault("page", "1"))
                 except ValueError: 1
      let perPage = try: parseInt(request.params.getOrDefault("per_page", "10"))
                    except ValueError: 10
      let perPageClamped = max(1, min(perPage, 50))
      let offset = max(0, (page - 1)) * perPageClamped

      let countRow = db.getRow(
        sql"SELECT COUNT(*) FROM brews WHERE user_id = ?",
        userId
      )
      let total = parseInt(countRow[0])
      let totalPages = max(1, (total + perPageClamped - 1) div perPageClamped)

      let brews = db.getAllRows(
        sql"""SELECT id, method, grind, rating, notes, created_at
              FROM brews WHERE user_id = ?
              ORDER BY created_at DESC
              LIMIT ? OFFSET ?""",
        userId, perPageClamped, offset
      )

      var listHtml = ""
      if brews.len == 0:
        listHtml = """<div class="empty-state">
          <p>No brews logged yet.</p>
          <a href="/brews/new" class="btn">Log your first brew</a>
        </div>"""
      else:
        for row in brews:
          let brewM     = h(row[1])
          let grind     = h(row[2])
          let rating    = parseInt(row[3])
          let notes     = h(row[4])
          let createdAt = row[5]
          let shortDate = h(if createdAt.len >= 10: createdAt[0..9] else: createdAt)

          listHtml.add("""<div class="card">""")
          listHtml.add("""<div class="card-header">""")
          listHtml.add("""<span class="card-title">""" & methodLabel(row[1]) & " " & brewM & "</span>")
          listHtml.add("""<span class="card-meta">""" & shortDate & "</span>")
          listHtml.add("</div>")
          listHtml.add("<div>" & starsHtml(rating) &
            """ <span class="card-detail">Grind: """ & grind & "</span></div>")
          if notes.len > 0:
            listHtml.add("""<div class="card-detail">""" & notes & "</div>")
          listHtml.add("</div>")

      var pagHtml = ""
      if totalPages > 1:
        pagHtml.add("""<div class="pagination">""")
        if page > 1:
          pagHtml.add("""<a href="/brews?page=""" & $(page-1) &
            "&amp;per_page=" & $perPageClamped & """">← Previous</a>""")
        else:
          pagHtml.add("""<span>← Previous</span>""")
        pagHtml.add("""<span class="current">Page """ & $page &
          " of " & $totalPages & "</span>")
        if page < totalPages:
          pagHtml.add("""<a href="/brews?page=""" & $(page+1) &
            "&amp;per_page=" & $perPageClamped & """">Next →</a>""")
        else:
          pagHtml.add("""<span>Next →</span>""")
        pagHtml.add("</div>")

      let body = """<h1>Brew Log</h1>
        <p style="margin-bottom:1.25rem;">
          <a href="/brews/new" class="btn">+ New Brew</a>
        </p>
        """ & listHtml & pagHtml
      resp page("Brew Log", body, loggedIn = true), "text/html"

  get "/brews/new":
    let userId = getSessionUserId(request)
    if userId < 0:
      redirect("/login")
    else:
      let body = """<h1>Log a Brew</h1>
        <form method="post" action="/brews">
          <div class="form-group">
            <label for="method">Brew Method</label>
            <select id="method" name="method" required>
              <option value="">— Select —</option>
              <option value="V60">V60</option>
              <option value="French Press">French Press</option>
              <option value="Aeropress">Aeropress</option>
              <option value="Chemex">Chemex</option>
              <option value="Espresso">Espresso</option>
              <option value="Kalita Wave">Kalita Wave</option>
              <option value="Moka Pot">Moka Pot</option>
              <option value="Cold Brew">Cold Brew</option>
              <option value="Other">Other</option>
            </select>
          </div>
          <div class="form-group">
            <label for="grind">Grind Size</label>
            <select id="grind" name="grind" required>
              <option value="">— Select —</option>
              <option value="Extra Fine">Extra Fine</option>
              <option value="Fine">Fine</option>
              <option value="Medium-Fine">Medium-Fine</option>
              <option value="Medium">Medium</option>
              <option value="Medium-Coarse">Medium-Coarse</option>
              <option value="Coarse">Coarse</option>
              <option value="Extra Coarse">Extra Coarse</option>
            </select>
          </div>
          <div class="form-group">
            <label for="rating">Rating (1–5)</label>
            <select id="rating" name="rating" required>
              <option value="">— Select —</option>
              <option value="1">1 ★ — Undrinkable</option>
              <option value="2">2 ★★ — Meh</option>
              <option value="3">3 ★★★ — Decent</option>
              <option value="4">4 ★★★★ — Really good</option>
              <option value="5">5 ★★★★★ — Exceptional</option>
            </select>
          </div>
          <div class="form-group">
            <label for="notes">Tasting Notes</label>
            <textarea id="notes" name="notes" placeholder="Flavour, aroma, what stood out…"></textarea>
          </div>
          <button type="submit">Save Brew</button>
          <a href="/brews" class="btn btn-outline" style="margin-left:0.5rem;">Cancel</a>
        </form>"""
      resp page("New Brew", body, loggedIn = true), "text/html"

  post "/brews":
    let userId = getSessionUserId(request)
    if userId < 0:
      redirect("/login")
    else:
      let brewM = request.params.getOrDefault("method")
      let grind = request.params.getOrDefault("grind")
      let ratingStr = request.params.getOrDefault("rating")
      let notes = request.params.getOrDefault("notes")

      if brewM.len == 0 or grind.len == 0 or ratingStr.len == 0:
        setCookie("bc_flash", "Method, grind, and rating are required.", path = "/")
        redirect("/brews/new")

      let rating = try: parseInt(ratingStr)
                   except ValueError: 0

      if rating < 1 or rating > 5:
        setCookie("bc_flash", "Rating must be between 1 and 5.", path = "/")
        redirect("/brews/new")

      db.exec(
        sql"""INSERT INTO brews (user_id, method, grind, rating, notes)
              VALUES (?, ?, ?, ?, ?)""",
        userId, brewM, grind, rating, notes
      )

      redirect("/brews")

  get "/beans":
    let userId = getSessionUserId(request)
    if userId < 0:
      redirect("/login")
    else:
      let beans = db.getAllRows(
        sql"""SELECT id, name, origin, roast, quantity
              FROM beans WHERE user_id = ?
              ORDER BY name""",
        userId
      )

      var tableHtml = ""
      if beans.len == 0:
        tableHtml = """<div class="empty-state">
          <p>No beans in your inventory yet.</p>
          <a href="/beans/new" class="btn">Add your first beans</a>
        </div>"""
      else:
        tableHtml = """<table>
          <thead><tr><th>Name</th><th>Origin</th><th>Roast</th><th>Qty (g)</th></tr></thead>
          <tbody>"""
        for row in beans:
          let name   = h(row[1])
          let origin = h(row[2])
          let roast  = h(row[3])
          let qty    = h(row[4])
          tableHtml.add("<tr><td><strong>" & name & "</strong></td>")
          tableHtml.add("<td>" & origin & "</td>")
          tableHtml.add("<td>" & roast & "</td>")
          tableHtml.add("<td>" & qty & "</td></tr>")
        tableHtml.add("</tbody></table>")

      let body = """<h1>Bean Inventory</h1>
        <p style="margin-bottom:1.25rem;">
          <a href="/beans/new" class="btn">+ Add Beans</a>
        </p>
        """ & tableHtml
      resp page("Bean Inventory", body, loggedIn = true), "text/html"

  get "/beans/new":
    let userId = getSessionUserId(request)
    if userId < 0:
      redirect("/login")
    else:
      let body = """<h1>Add Beans</h1>
        <form method="post" action="/beans">
          <div class="form-group">
            <label for="name">Bean Name</label>
            <input type="text" id="name" name="name" required placeholder="e.g. Ethiopia Yirgacheffe">
          </div>
          <div class="form-group">
            <label for="origin">Origin</label>
            <input type="text" id="origin" name="origin" placeholder="e.g. Ethiopia">
          </div>
          <div class="form-group">
            <label for="roast">Roast Level</label>
            <select id="roast" name="roast">
              <option value="">— Optional —</option>
              <option value="Light">Light</option>
              <option value="Medium-Light">Medium-Light</option>
              <option value="Medium">Medium</option>
              <option value="Medium-Dark">Medium-Dark</option>
              <option value="Dark">Dark</option>
            </select>
          </div>
          <div class="form-group">
            <label for="quantity">Quantity (grams)</label>
            <input type="number" id="quantity" name="quantity" value="250" min="0" step="1">
          </div>
          <button type="submit">Add Beans</button>
          <a href="/beans" class="btn btn-outline" style="margin-left:0.5rem;">Cancel</a>
        </form>"""
      resp page("Add Beans", body, loggedIn = true), "text/html"

  post "/beans":
    let userId = getSessionUserId(request)
    if userId < 0:
      redirect("/login")
    else:
      let name   = request.params.getOrDefault("name")
      let origin = request.params.getOrDefault("origin")
      let roast  = request.params.getOrDefault("roast")
      let qtyStr = request.params.getOrDefault("quantity")

      if name.len == 0:
        setCookie("bc_flash", "Bean name is required.", path = "/")
        redirect("/beans/new")

      let quantity = try: parseInt(qtyStr) except ValueError: 0

      db.exec(
        sql"""INSERT INTO beans (user_id, name, origin, roast, quantity)
              VALUES (?, ?, ?, ?, ?)""",
        userId, name, origin, roast, max(0, quantity)
      )

      redirect("/beans")

# ---------------------------------------------------------------------------
