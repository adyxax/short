# Package

version       = "0.1.0"
author        = "Julien Dessaux"
description   = "A simple, privacy friendly URL shortener"
license       = "EUPL-1.2"
srcDir        = "src"
bin           = @["short"]


# Dependencies

requires "nim >= 1.4.8",
         "https://github.com/dom96/jester#HEAD",
         "nimja >= 0.4.1",
         "https://github.com/GULPF/tiny_sqlite#HEAD"
