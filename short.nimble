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
         "https://github.com/GULPF/tiny_sqlite#HEAD",
         "uuids >= 0.1.11"

import os, strformat

task fmt, "Run nimpretty on all git-managed .nim files in the current repo":
  ## Usage: nim fmt
  for file in walkDirRec("./", {pcFile, pcDir}):
    if file.splitFile().ext == ".nim":
      let
        # https://github.com/nim-lang/Nim/issues/6262#issuecomment-454983572
        # https://stackoverflow.com/a/2406813/1219634
        fileIsGitManaged = gorgeEx("cd $1 && git ls-files --error-unmatch $2" % [getCurrentDir(), file]).exitCode == 0
        #                           ^^^^^-- That "cd" is required.
      if fileIsGitManaged:
        let
          cmd = "nimpretty --maxLineLen=220 $1" % [file]
        echo "Running $1 .." % [cmd]
        exec(cmd)
