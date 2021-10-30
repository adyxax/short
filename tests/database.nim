include ../src/database

import unittest

const someTime = initDuration(seconds = 1)
let testingNow = times.now() - 60 * someTime
let later = testingNow + 30 * someTime

suite "database":
  test "url":
    let db = openDatabase(":memory:")
    check db.Migrate() == true
    let u = ShortUrl(
      Token: "Az0f8uSeK9",
      Title: "title",
      Url: "url",
      Created: testingNow,
      Expires: later,
    )
    db.AddUrl(u)
    try:
      db.AddUrl(u)
      check false
    except SqliteError:
      discard
    var u2 = db.GetUrl(u.Token)
    check u2.ID == 1
    check u2.Token == u.Token
    check u2.Title == "title"
    check u2.Url == "url"
    check u2.Created - testingNow < someTime
    check u2.Expires - later < someTime
    db.CleanExpired()
    try:
      discard db.GetUrl(u.Token)
    except SqliteError:
      check false
    u2.Expires = testingNow + 120 * someTime
    db.AddUrl(u2[])
    db.CleanExpired()
    check db.GetUrl(u.Token) != nil
