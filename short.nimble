# Package

version       = "0.1.0"
author        = "Julien Dessaux"
description   = "A simple, privacy friendly URL shortener"
license       = "EUPL-1.2"
srcDir        = "src"
bin           = @["short"]


# Dependencies

requires "nim >= 1.4.8",
         "jester > 0.5.0",
         "nimja >= 0.4.1",
         "tiny_sqlite > 0.1.2"
