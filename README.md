# short : A simple, privacy friendly URL shortener written in nim

This repository contains code for a nim web service that can shorten a valid URL. The goals of the project are to be simple to use, light (about 7M of ram), self-hosted, open source and privacy friendly : anonymous usage, no tracking. I especially wanted an URL shortener that would display the target URL for people to review before clicking, and not simply redirect.

It is also a learning project, being my first web service written in nim.

## Contents

- [Dependencies](#dependencies)
- [Quick install](#quick-install)
- [Usage](#usage)
- [Building](#building)
- [Running tests](#running-tests)

## Dependencies

nim is required. Only nim version >= 1.4.8 on linux amd64 (Gentoo) is being regularly tested.

The following nim libraries will be pulled by nimble when installing :
* jester
* nanoid
* nimja
* tiny_sqlite

## Quick Install

To install, clone this repository then run :
```
nimble install
```

## Usage

Launching the interpreter is as simple as :
```
short
```

The server needs to be started from a place with a `./data/` directory. It will open (or create if it does not already exist) a sqlite3 database in `./data/short.db`, then start listening on `0.0.0.0:5000` for http connections.

## Building

For a debug build, use :
```
nimble build
```

For a release build, use :
```
nimble build -d:release
```

## Running tests

To run unit tests, use :
```
nimble tests
```

To debug a particular tests, use :
```
nim c --debugger:on --parallelBuild:1 --debuginfo --linedir:on tests/database.nim
gdb tests/database
b src/truc.nim:123
r
```
