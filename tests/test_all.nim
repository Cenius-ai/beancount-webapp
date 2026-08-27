## Integration tests for BeanCount
## Run with: nimble test (server must be running on PORT 5000)

import std/[os, strutils, httpclient, httpcore, uri]

const BaseUrl = "http://localhost:" & getEnv("PORT", "5000")

var passed = 0
var failed = 0

proc check(name: string, ok: bool) =
  if ok:
    echo "  PASS  ", name
    inc passed
  else:
    echo "  FAIL  ", name
    inc failed

proc postForm(client: HttpClient, url: string, body: string): Response =
  let h = newHttpHeaders({"Content-Type": "application/x-www-form-urlencoded"})
  result = client.request(url, httpMethod = HttpPost, body = body, headers = h)

proc getWithCookie(url: string, sid: string): string =
  let client = newHttpClient(maxRedirects = 5)
  client.headers = newHttpHeaders({"Cookie": "sid=" & sid})
  result = client.getContent(url)
  client.close()

proc postFormWithCookie(url, body, sid: string): Response =
  let client = newHttpClient(maxRedirects = 0)
  let h = newHttpHeaders({
    "Content-Type": "application/x-www-form-urlencoded",
    "Cookie": "sid=" & sid
  })
  result = client.request(url, httpMethod = HttpPost, body = body, headers = h)
  client.close()

proc postWithCookie(url, sid: string): Response =
  let client = newHttpClient(maxRedirects = 0)
  client.headers = newHttpHeaders({"Cookie": "sid=" & sid})
  result = client.request(url, httpMethod = HttpPost)
  client.close()

proc main() =
  echo "BeanCount integration tests"
  echo "==========================="
  echo ""

  # Client for redirect-check tests (no follow)
  var noFollow = newHttpClient(maxRedirects = 0)

  # Test 1: GET /login
  block:
    let resp = noFollow.get(BaseUrl & "/login")
    check("GET /login returns 200", resp.code == Http200)

  # Test 2: Demo hint
  block:
    let client = newHttpClient(maxRedirects = 5)
    let body = client.getContent(BaseUrl & "/login")
    client.close()
    check("Login page shows demo hint",
      body.find("cenius@cenius.ai") >= 0 and body.find("cenius") >= 0)

  # Test 3: Unauthenticated redirect
  block:
    let resp = noFollow.get(BaseUrl & "/")
    check("GET / redirects when unauthenticated",
      resp.code == Http302)

  # Test 4: Login success — also extract the session cookie
  var sid = ""
  block:
    let resp = postForm(noFollow, BaseUrl & "/login",
      "email=cenius@cenius.ai&password=cenius")
    let locOk = resp.headers.getOrDefault("location") == "/brews"
    let setCookie = resp.headers.getOrDefault("set-cookie")
    let cookieOk = setCookie.len > 0
    # Extract sid from Set-Cookie
    if setCookie.len > 0:
      let start = setCookie.find("sid=")
      if start >= 0:
        let valStart = start + 4
        let valEnd = setCookie.find(";", valStart)
        if valEnd >= 0:
          sid = setCookie[valStart .. valEnd - 1]
        else:
          sid = setCookie[valStart .. ^1]
    check("POST /login with demo credentials succeeds",
      resp.code == Http302 and locOk and cookieOk)

  # Test 5: Login failure
  block:
    let resp = postForm(noFollow, BaseUrl & "/login",
      "email=cenius@cenius.ai&password=wrong")
    check("POST /login with wrong password fails",
      resp.code == Http302 and
      resp.headers.getOrDefault("location").find("error") >= 0)

  # Test 6: Missing fields
  block:
    let resp = postForm(noFollow, BaseUrl & "/login", "email=")
    check("POST /login with missing fields fails",
      resp.code == Http302 and
      resp.headers.getOrDefault("location").find("error") >= 0)

  # Test 7: Protected route redirects
  block:
    let resp = noFollow.get(BaseUrl & "/brews")
    check("GET /brews redirects when unauthenticated",
      resp.code == Http302)

  noFollow.close()

  # ── Authenticated tests using extracted sid ─────────────────────────
  block:
    let body = getWithCookie(BaseUrl & "/brews", sid)
    check("GET /brews shows brew entries when authenticated",
      body.find("Brew Log") >= 0 and body.find("brew-card") >= 0)

  block:
    let body = getWithCookie(BaseUrl & "/brews/new", sid)
    check("GET /brews/new returns form when authenticated",
      body.find("New Brew") >= 0)

  block:
    let resp = postFormWithCookie(BaseUrl & "/brews",
      "method=V60&grind=Medium&rating=4&notes=Test", sid)
    check("POST /brews creates a brew",
      resp.code == Http302 and
      resp.headers.getOrDefault("location").find("/brews") >= 0)

  block:
    let resp = postFormWithCookie(BaseUrl & "/brews",
      "method=V60&grind=Medium&rating=9&notes=Bad", sid)
    check("POST /brews with invalid rating fails",
      resp.code == Http302 and
      resp.headers.getOrDefault("location").find("error") >= 0)

  block:
    let body = getWithCookie(BaseUrl & "/beans", sid)
    check("GET /beans shows inventory when authenticated",
      body.find("Bean Inventory") >= 0)

  block:
    let resp = postFormWithCookie(BaseUrl & "/beans",
      "name=Test+Bean&origin=Testland&roast=Medium&quantity=250", sid)
    check("POST /beans creates a bean",
      resp.code == Http302 and
      resp.headers.getOrDefault("location").find("/beans") >= 0)

  block:
    let body = getWithCookie(BaseUrl & "/beans/new", sid)
    check("GET /beans/new returns form when authenticated",
      body.find("Add Beans") >= 0)

  block:
    let resp = postWithCookie(BaseUrl & "/logout", sid)
    check("POST /logout clears session",
      resp.code == Http302 and
      resp.headers.getOrDefault("location") == "/login")

  block:
    let body = getWithCookie(BaseUrl & "/brews?page=1&per_page=5", sid)
    check("Pagination: page with per_page=5 renders",
      body.find("Brew Log") >= 0 and body.find("brew-card") >= 0)

  echo ""
  echo "Results: ", passed, " passed, ", failed, " failed"
  if failed > 0:
    quit(1)

when isMainModule:
  main()
