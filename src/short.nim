import os, strutils
import std/[hashes, re, sequtils, times, uri]

import tiny_sqlite
import jester
import nimja/parser
import nanoid

import database

const nanoidAlphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const nanoidSize = 10

const allCss = staticRead("../static/all.css")
const cssRoute = "/static/all.css." & $hash(allCss)
const favicon = staticRead("../static/favicon.ico")
const faviconSvg = staticRead("../static/favicon.svg")

const secureHeaders = @[
  ("X-Frame-Options", "deny"),
  ("X-XSS-Protection", "1; mode=block"),
  ("X-Content-Type-Options", "nosniff"),
  ("Referrer-Policy", "strict-origin"),
  ("Cache-Control", "no-transform"),
  ("Content-Security-Policy", "script-src 'self'"),
  ("Permissions-Policy", "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()"),
  ("Strict-Transport-Security", "max-age=16000000;"),
]
const nonCachingHeaders = concat(secureHeaders, @[("Cache-Control", "max-age=0" )])
const htmlHeaders = concat(nonCachingHeaders, @[("content-type", "text/html")])
const cachingHeaders = concat(secureHeaders, @[("Cache-Control", "public, max-age=31536000, immutable" )])
const cssHeaders = concat(cachingHeaders, @[("content-type", "text/css")])
const icoHeaders = concat(cachingHeaders, @[("content-type", "image/x-icon")])
const svgHeaders = concat(cachingHeaders, @[("content-type", "image/svg+xml")])

var db {.threadvar.}: DbConn

proc initDB() {.raises: [SqliteError].} =
  if not db.isOpen():
    db = openDatabase("data/short.db")

func renderIndex(): string {.raises: [].} =
  var req: ShortUrl
  compileTemplateFile(getScriptDir() / "templates/index.html")

func renderAbout(): string {.raises: [].} =
  compileTemplateFile(getScriptDir() / "templates/about.html")

func renderShort(req: ShortUrl): string {.raises: [].} =
  compileTemplateFile(getScriptDir() / "templates/short.html")

func renderNoShort(req: ShortUrl): string {.raises: [].} =
  compileTemplateFile(getScriptDir() / "templates/noshort.html")

func renderError(code: int, msg: string): string {.raises: [].} =
  compileTemplateFile(getScriptDir() / "templates/error.html")

proc handleToken(token: string): (HttpCode, string) {.raises: [].} =
  try:
    let tokenRegexp = re"^[\w]{10}$"
    if not match(token, tokenRegexp):
      return (Http400, renderError(400, "Bad Request"))
  except RegexError:
    return (Http500, renderError(500, "RegexError"))
  db.CleanExpired()
  try:
    let req = db.GetUrl(token)
    if req == nil:
      return (Http404, renderNoShort(req[]))
    return (Http200, renderShort(req[]))
  except SqliteError:
    return (Http500, renderError(500, "SqliteError"))

proc handleIndexPost(params: Table[string, string]): (HttpCode, string) {.raises: [].} =
  var input: ShortUrl
  var exp: int
  for k, v in params.pairs:
    case k:
      of "title":
        try:
          let titleRegexp = re"^[\w\s]{3,64}$"
          if match(v, titleRegexp):
            input.Title = v
          else:
            return (Http400, renderError(400, "Bad Request"))
        except RegexError:
          return (Http500, renderError(500, "RegexError"))
      of "url":
        try:
          discard parseUri(v)
          input.Url = v
        except:
          return (Http400, renderError(400, "Bad Request"))
      of "expires":
        try:
          exp = parseInt(v)
        except ValueError:
          return (Http400, renderError(400, "Bad Request"))
        if exp < 1 or exp > 527040:
          return (Http400, renderError(400, "Bad Request"))
      of "shorten": discard
      else: return (Http400, renderError(400, "Bad Request"))
  if input.Title == "" or input.Url == "" or exp == 0:
    return (Http400, renderError(400, "Bad Request"))
  try:
    input.Token = generate(alphabet=nanoidAlphabet, size=nanoidSize)
  except IOError:
    return (Http500, renderError(500, "IOError on UUID generation"))
  except OSError:
    return (Http500, renderError(500, "OSError on UUID generation"))
  input.Created = times.now()
  input.Expires = input.Created + initDuration(minutes = exp)
  try:
    db.AddUrl(input)
  except SqliteError:
    return (Http500, renderShort(input))
  return (Http200, $input.Token)

routes:
  get "/":
    resp Http200, htmlHeaders, renderIndex()
  get "/about":
    resp Http200, htmlHeaders, renderAbout()
  post "/":
    initDB()
    var (code, content) = handleIndexPost(request.params)
    if code != Http200:
      resp code, htmlHeaders, content
    else:
      redirect("/" & content)
  get "/static/favicon.ico":
    resp Http200, icoHeaders, favicon
  get "/static/favicon.svg":
    resp Http200, svgHeaders, faviconSvg
  get re"^/static/all\.css\.":
    resp Http200, cssHeaders, allcss
  get "/@token":
    initDB()
    var (code, content) = handleToken(@"token")
    resp code, htmlHeaders, content

when isMainModule:
  initDb()
  if not db.Migrate():
    echo "Failed to migrate database schema"
    quit 1
  db.close()
  runForever()
