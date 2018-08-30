# Todoist API REST v8
# http://doist.github.io/todoist-api/rest/v8

import os, strutils
import ntodopkg/globals
import ntodopkg/projects as p

proc doStuff(data, projectAction: string) =
  ## Doer proc.
  var str = ""
  str = if projectAction != "":
          p.action(data, projectAction)
        else:
          "User needs to select one of the sub-command switches like -p/--project."
  echo str

proc main*(data = "", project = "") =
  ## Main proc.
  try:
    doStuff(data, project)
  except:
    echo "  [ERROR] " & getCurrentExceptionMsg() & "\n"

when isMainModule:
  import cligen
  # Use dispatchGen to do some initial setup for cligen, but don't run main, yet..
  dispatchGen(main,
              version = ("version", "0.1.0"))
  if paramCount()==0:
    quit(dispatch_main(@["--help"]))
  else:
    quit(dispatch_main(commandLineParams()))

# https://gist.github.com/piotrklibert/b2ba0774244bb7368748a3b8b038c5f9
# https://gitter.im/nim-lang/Nim?at=5b85b35260f9ee7aa4a50361
# https://nim-lang.org/docs/httpclient.html
# https://nim-lang.org/docs/json.html
