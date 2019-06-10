# Package

version       = "0.1.3"
author        = "Kaushal Modi"
description   = "A CLI app to execute basic Todoist functions via its API"
license       = "MIT"
srcDir        = "src"
bin           = @["ntodo"]

# Dependencies

requires "nim >= 0.18.1", "cligen >= 0.9.31"
