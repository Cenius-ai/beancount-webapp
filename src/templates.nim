## Server-rendered HTML templates with embedded CSS.
## Every template returns a complete HTML string.

import std/strutils
import auth  # for htmlEscape

proc h(s: string): string = htmlEscape(s)

const css* = """

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
    --font-mono:       'Hanken Grotesk', monospace;
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  html {
    font-size: 16px;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }

  body {
    font-family: var(--font-body);
    background: var(--background);
    color: var(--foreground);
    line-height: 1.6;
    min-height: 100vh;
  }

  /* ── top bar ── */
  .topbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 1.5rem;
    height: 3.5rem;
    background: var(--card);
    border-bottom: 2px solid var(--border);
    position: sticky;
    top: 0;
    z-index: 10;
  }

  .topbar-brand {
    font-family: var(--font-display);
    font-size: 1.125rem;
    font-weight: 700;
    letter-spacing: -0.01em;
    color: var(--foreground);
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .topbar-brand::before {
    content: '';
    display: inline-block;
    width: 1.5rem;
    height: 1.5rem;
    background: var(--accent);
    border-radius: var(--radius);
  }

  .topbar-nav {
    display: flex;
    align-items: center;
    gap: 0.25rem;
  }

  .topbar-nav a {
    color: var(--muted-foreground);
    text-decoration: none;
    padding: 0.375rem 0.75rem;
    border-radius: var(--radius);
    font-size: 0.875rem;
    font-weight: 600;
    font-family: var(--font-body);
    transition: background 150ms ease, color 150ms ease;
  }

  .topbar-nav a:hover,
  .topbar-nav a.active {
    color: var(--foreground);
    background: var(--secondary);
  }

  .topbar-nav .btn-logout {
    color: var(--muted-foreground);
    background: none;
    border: 2px solid var(--border);
    cursor: pointer;
    font-family: var(--font-body);
    font-size: 0.8125rem;
    font-weight: 600;
    padding: 0.3125rem 0.75rem;
    border-radius: var(--radius);
    transition: background 150ms, color 150ms;
    margin-left: 0.5rem;
  }

  .topbar-nav .btn-logout:hover {
    color: var(--destructive);
    border-color: var(--destructive);
  }

  /* ── content column ── */
  .content {
    max-width: 48rem;
    margin: 0 auto;
    padding: 2rem 1.5rem 4rem;
  }

  /* ── page header ── */
  .page-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 1.5rem;
  }

  .page-header h1 {
    font-family: var(--font-display);
    font-size: 1.5rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    color: var(--foreground);
  }

  /* ── cards & surfaces ── */
  .card {
    background: var(--card);
    border: 2px solid var(--border);
    border-radius: var(--radius);
    padding: 1.25rem;
    margin-bottom: 0.75rem;
    transition: border-color 150ms ease;
    box-shadow: none;
  }

  .card:hover {
    border-color: var(--accent);
  }

  /* ── buttons ── */
  .btn {
    display: inline-flex;
    align-items: center;
    gap: 0.375rem;
    font-family: var(--font-body);
    font-size: 0.875rem;
    font-weight: 700;
    padding: 0.5rem 1rem;
    border-radius: var(--radius);
    border: 2px solid transparent;
    cursor: pointer;
    text-decoration: none;
    transition: background 150ms ease, border-color 150ms ease, color 150ms ease;
    box-shadow: none;
  }

  .btn-primary {
    background: var(--primary);
    color: var(--on-primary);
    border-color: var(--primary);
  }

  .btn-primary:hover {
    background: var(--primary);
    opacity: 0.88;
    border-color: var(--primary);
  }

  .btn-secondary {
    background: var(--secondary);
    color: var(--on-secondary);
    border-color: var(--border);
  }

  .btn-secondary:hover {
    background: var(--muted);
    border-color: var(--accent);
  }

  .btn-danger {
    background: transparent;
    color: var(--destructive);
    border-color: var(--destructive);
  }

  .btn-danger:hover {
    background: #fef2f2;
  }

  /* ── forms ── */
  .form-group {
    margin-bottom: 1rem;
  }

  .form-group label {
    display: block;
    font-size: 0.8125rem;
    font-weight: 600;
    color: var(--muted-foreground);
    margin-bottom: 0.25rem;
    font-family: var(--font-body);
  }

  .form-group input,
  .form-group select,
  .form-group textarea {
    width: 100%;
    padding: 0.5625rem 0.75rem;
    font-family: var(--font-body);
    font-size: 0.9375rem;
    color: var(--foreground);
    background: var(--card);
    border: 2px solid var(--border);
    border-radius: var(--radius);
    transition: border-color 150ms ease;
  }

  .form-group input:focus,
  .form-group select:focus,
  .form-group textarea:focus {
    outline: none;
    border-color: var(--accent);
  }

  .form-group select {
    cursor: pointer;
  }

  .form-group textarea {
    resize: vertical;
    min-height: 5rem;
  }

  /* ── login page ── */
  .login-container {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    padding: 2rem;
  }

  .login-card {
    background: var(--card);
    border: 2px solid var(--border);
    border-radius: var(--radius);
    padding: 2rem;
    width: 100%;
    max-width: 24rem;
    box-shadow: none;
  }

  .login-card h1 {
    font-family: var(--font-display);
    font-size: 1.375rem;
    font-weight: 700;
    letter-spacing: -0.01em;
    margin-bottom: 0.25rem;
    color: var(--foreground);
  }

  .login-card .subtitle {
    color: var(--muted-foreground);
    font-size: 0.875rem;
    margin-bottom: 1.5rem;
    font-family: var(--font-body);
  }

  .demo-hint {
    background: var(--secondary);
    border: 2px solid var(--accent);
    border-radius: var(--radius);
    padding: 0.75rem 1rem;
    margin-bottom: 1.5rem;
    font-size: 0.8125rem;
    color: var(--muted-foreground);
    font-family: var(--font-body);
  }

  .demo-hint strong {
    color: var(--accent);
    font-weight: 700;
  }

  /* ── flash messages ── */
  .flash {
    padding: 0.625rem 1rem;
    border-radius: var(--radius);
    margin-bottom: 1rem;
    font-size: 0.875rem;
    font-family: var(--font-body);
    font-weight: 600;
  }

  .flash-error {
    background: #fef2f2;
    border: 2px solid var(--destructive);
    color: var(--destructive);
  }

  .flash-success {
    background: #f0fdf4;
    border: 2px solid #16a34a;
    color: #16a34a;
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(-4px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  /* ── brew card ── */
  .brew-card {
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    padding: 1rem 1.25rem;
  }

  .brew-rating {
    display: flex;
    align-items: center;
    gap: 0.125rem;
    font-family: var(--font-display);
    font-size: 0.9375rem;
    font-weight: 700;
    color: var(--accent);
    white-space: nowrap;
    min-width: 4rem;
  }

  .brew-rating .stars {
    color: var(--muted-foreground);
    font-size: 0.75rem;
  }

  .brew-body {
    flex: 1;
    min-width: 0;
  }

  .brew-method {
    font-weight: 700;
    font-size: 0.9375rem;
    color: var(--foreground);
    font-family: var(--font-display);
  }

  .brew-meta {
    display: flex;
    gap: 1rem;
    font-size: 0.8125rem;
    color: var(--muted-foreground);
    margin-top: 0.125rem;
    font-family: var(--font-body);
  }

  .brew-notes {
    font-size: 0.875rem;
    color: var(--muted-foreground);
    margin-top: 0.375rem;
    line-height: 1.5;
    font-family: var(--font-body);
  }

  .brew-date {
    font-size: 0.75rem;
    color: var(--muted-foreground);
    white-space: nowrap;
    font-family: var(--font-body);
  }

  /* ── bean card ── */
  .bean-card {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 1rem 1.25rem;
  }

  .bean-info h3 {
    font-size: 0.9375rem;
    font-weight: 700;
    color: var(--foreground);
    font-family: var(--font-display);
  }

  .bean-info .bean-meta {
    font-size: 0.8125rem;
    color: var(--muted-foreground);
    margin-top: 0.125rem;
    font-family: var(--font-body);
  }

  .bean-quantity {
    font-family: var(--font-display);
    font-size: 0.875rem;
    font-weight: 700;
    color: var(--muted-foreground);
    white-space: nowrap;
  }

  /* ── pagination ── */
  .pagination {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.75rem;
    margin-top: 1.5rem;
  }

  .pagination .page-info {
    font-size: 0.8125rem;
    color: var(--muted-foreground);
    font-family: var(--font-body);
  }

  /* ── empty state ── */
  .empty-state {
    text-align: center;
    padding: 3rem 1.5rem;
    color: var(--muted-foreground);
    font-family: var(--font-body);
  }

  .empty-state p {
    margin-bottom: 1rem;
    font-size: 0.9375rem;
  }

  .empty-state .sub {
    font-size: 0.8125rem;
    color: var(--muted-foreground);
  }

  /* ── misc ── */
  .text-muted { color: var(--muted-foreground); font-size: 0.8125rem; }
  .mt-2 { margin-top: 0.5rem; }
  .mt-4 { margin-top: 1rem; }
  .mb-2 { margin-bottom: 0.5rem; }
  .mb-4 { margin-bottom: 1rem; }

  hr {
    border: none;
    border-top: 2px solid var(--border);
    margin: 1.5rem 0;
  }

  /* ── responsive ── */
  @media (max-width: 640px) {
    .content { padding: 1rem; }
    .brew-card { flex-direction: column; gap: 0.5rem; }
    .brew-date { align-self: flex-end; }
    .page-header { flex-direction: column; align-items: flex-start; gap: 0.75rem; }
  }
"""

proc baseHtml*(title: string, bodyContent: string, loggedIn: bool = false): string =
  ## Wrap content in the standard HTML shell.
  let navHtml = if loggedIn:
    """<nav class="topbar">
  <a href="/brews" class="topbar-brand">BeanCount</a>
  <div class="topbar-nav">
    <a href="/brews">Brews</a>
    <a href="/beans">Beans</a>
    <form method="POST" action="/logout" style="display:inline">
      <button type="submit" class="btn-logout">Log out</button>
    </form>
  </div>
</nav>"""
  else:
    ""

  result = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n" &
    "<meta charset=\"utf-8\">\n" &
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n" &
    "<title>" & h(title) & " — BeanCount</title>\n" &
    "<style>" & css & "</style>\n" &
    "</head>\n<body>\n" &
    navHtml &
    "<main class=\"content\">\n" &
    bodyContent &
    "\n</main>\n</body>\n</html>"

proc loginPage*(errorMsg: string = ""): string =
  ## Render the login page.
  let errorHtml = if errorMsg.len > 0:
    "<div class=\"flash flash-error\">" & h(errorMsg) & "</div>"
  else:
    ""

  let body = """
<div class="login-container">
  <div class="login-card">
    <h1>BeanCount</h1>
    <p class="subtitle">Your coffee brew journal</p>

    <div class="demo-hint">
      <strong>Demo:</strong> cenius@cenius.ai / cenius
    </div>

    """ & errorHtml & """

    <form method="POST" action="/login">
      <div class="form-group">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" required autofocus
               placeholder="cenius@cenius.ai">
      </div>
      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" required
               placeholder="········">
      </div>
      <button type="submit" class="btn btn-primary" style="width:100%">
        Sign in
      </button>
    </form>
  </div>
</div>"""

  result = baseHtml("Sign in", body, loggedIn = false)

proc brewEntryHtml*(id: int64, `method`, grind: string, rating: int,
                    notes, createdAt: string): string =
  ## Render a single brew card. All user-supplied values are HTML-escaped.
  let stars = repeat("★", rating) & repeat("☆", 5 - rating)
  result = "<div class=\"card brew-card\">\n" &
    "  <div class=\"brew-rating\">" & $rating & "/5" &
    " <span class=\"stars\">" & stars & "</span></div>\n" &
    "  <div class=\"brew-body\">\n" &
    "    <div class=\"brew-method\">" & h(`method`) & "</div>\n" &
    "    <div class=\"brew-meta\">\n" &
    "      <span>Grind: " & h(grind) & "</span>\n" &
    "    </div>\n" &
    (if notes.len > 0: "    <div class=\"brew-notes\">" & h(notes) & "</div>\n"
     else: "") &
    "  </div>\n" &
    "  <div class=\"brew-date\">" & h(createdAt) & "</div>\n" &
    "</div>"

proc beanEntryHtml*(id: int64, name, origin, roast: string, quantity: int): string =
  ## Render a single bean card. All user-supplied values are HTML-escaped.
  let originRoast =
    if origin.len > 0 and roast.len > 0: h(origin) & " · " & h(roast)
    elif origin.len > 0: h(origin)
    elif roast.len > 0: h(roast)
    else: ""

  result = "<div class=\"card bean-card\">\n" &
    "  <div class=\"bean-info\">\n" &
    "    <h3>" & h(name) & "</h3>\n" &
    (if originRoast.len > 0:
       "    <div class=\"bean-meta\">" & originRoast & "</div>\n"
     else: "") &
    "  </div>\n" &
    "  <div class=\"bean-quantity\">" & $quantity & " g</div>\n" &
    "</div>"
