# Todoist API REST v8
# http://doist.github.io/todoist-api/rest/v8

import std/[os, strutils, strformat, sequtils, sugar]
import ntodopkg/globals
import ntodopkg/projects as p
import ntodopkg/tasks as t

# https://gitter.im/nim-lang/Nim?at=5b8841e1f5402f32aab447f1
proc isOneHot(s: openArray[string]): bool =
  ## Returns true only if one element in S is a non-empty string.
  s.filter(s => s != "").len == 1

proc doStuff(data, projectAction, taskAction: string) =
  ## Doer proc.
  var str = ""
  if projectAction != "":
    str = p.action(data, projectAction)
  elif taskAction != "":
    str = t.action(data, taskAction)
  echo str

proc ntodo*(data = "", project = "", task = "") =
  ## A CLI app to execute basic Todoist functions via its API.
  try:
    if (not isOneHot(@[project, task])):
      raise newException(UserError, "User needs to select only one of the sub-command switches: -p/--project, -t/--task.")
    doStuff(data, project, task)
  except:
    echo "\n" & fmt"[Error] {getCurrentException().name}: {getCurrentException().msg}"

when isMainModule:
  import cligen

  # https://github.com/c-blake/cligen/issues/83#issuecomment-444951772
  proc mergeParams(cmdNames: seq[string], cmdLine = commandLineParams()): seq[string] =
    result = cmdLine
    if cmdLine.len == 0:
      result = @["--help"]

  const
    version = staticExec("git describe --tags HEAD")
    nimbleData = staticRead("../ntodo.nimble")
    uri = "https://github.com/kaushalmodi/ntodo"
    # https://github.com/c-blake/cligen/issues/107
    myUsage = "\nNAME\n  ntodo - ${doc}" &
      "\nUSAGE\n  ${command} ${args}" &
      "\n\nOPTIONS\n$options" &
      "\nURI\n  " & uri &
      "\n\nAUTHOR\n  " & nimbleData.fromNimble("author") &
      "\n\nVERSION\n  " & version

  # https://github.com/c-blake/cligen/blob/master/RELEASE-NOTES.md#version-0928
  clCfg.version = version

  dispatch(ntodo, usage = myUsage)

# https://gist.github.com/piotrklibert/b2ba0774244bb7368748a3b8b038c5f9
# https://gitter.im/nim-lang/Nim?at=5b85b35260f9ee7aa4a50361
# https://nim-lang.org/docs/httpclient.html
# https://nim-lang.org/docs/json.html
