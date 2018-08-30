# Todoist API REST v8
# http://doist.github.io/todoist-api/rest/v8

import os, strutils
import ntodopkg/globals
import ntodopkg/projects as p

proc doStuff(action, data: string) =
  ## Doer proc.
  var ret: string
  ret = case action
        of "plist":
          p.getAll()
        of "pget":
          echo p.getAll(withIndex = true)
          stdout.write("Type the project index (number in the first column) that you need to get: ")
          let
            idx = readLine(stdin).strip().parseInt()
          p.get(idx)
        of "pcreate":
          if data == "":
            raise newException(UserError, "New project name needs to be provided using the '-d' switch.")
          p.create(data)
        else:
          p.getAll()
  echo ret

proc main*(action: string = "plist", data: string = "") =
  ## Main proc.
  try:
    doStuff(action, data)
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
