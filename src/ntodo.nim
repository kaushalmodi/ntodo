# Todoist API REST v8
# http://doist.github.io/todoist-api/rest/v8

import os, options, httpclient, json, strutils, strformat, typetraits, random

const
  tokenFileName = ".todoist-token"
  apiBaseUrl = "https://beta.todoist.com/API/v8"

type
  UserError = object of Exception

var
  client: Option[HttpClient]

proc getToken(): string =
  ## Get Todoist API token
  return tokenFileName.readFile().strip()

proc getUuid(): string =
  ## Generate a 36-digit UUID string like ``uuidgen`` in Unix.
  ## Example: e0e7df1f-5bd4-4196-a0a2-26cd6a007c6c
  #                        1    1    2
  #           0       8    3    8    3
  result = ""
  for i in 0 .. 35:
    if i in {8, 13, 18, 23}:
      result = result & "-"
    else:
      randomize()
      let r = rand(15)
      result = result & fmt"{r:#x}"[2 .. 2]

proc getClient(): HttpClient =
  ## Create a new http client if one doesn't already exist.
  if isNone(client):
    var c = newHttpClient()
    c.headers = newHttpHeaders({ "Authorization" : "Bearer " & getToken() })
    client = some(c)
  get(client)

proc getApiUrl(cmd: string): string =
  ## Get the full API URL for a command.
  return apiBaseUrl & "/" & cmd

proc requestGet(url: string): JsonNode =
  ## Get JSON object returned from a GET request to URL.
  try:
    return getClient().getContent(url).parseJson()
  except:
    echo "Error: Unable to get contents from " & url
    return "[]".parseJson()

proc requestPost(url, data: string): JsonNode =
  ## Get JSON object returned from a POST request to URL.
  try:
    var c = getClient()
    c.headers = newHttpHeaders({ "Content-Type": "application/json",
                                 "X-Request-Id": getUuid(),
                                 "Authorization": "Bearer " & getToken() })
    return c.request(url, httpMethod = HttpPost, body = data).body.parseJson()
  except:
    echo "Error: Unable to get contents from " & url
    return "[]".parseJson()

proc projectsGet(): string =
  ## Get projects.
  ## https://developer.todoist.com/rest/v8/#get-all-projects
  let
    jsonObj = getApiUrl("projects").requestGet()
  var
    idx = 0
  result = "Projects:\n\n"
  for proj in jsonObj:
    # https://developer.todoist.com/rest/v8/#projects
    # id, name, comment_count, order, indent
    let
      order = proj["order"].getInt
      indent = " ".repeat(proj["indent"].getInt)
      id = proj["id"].getInt
      name = proj["name"].getStr
    # echo fmt"order ({$order.type}) = {order}"
    # echo fmt"idx ({$idx.type}) = {idx}"
    doAssert idx == order
    result = result & fmt"{indent}{name} ({id})" & "\n"
    idx += 1

proc projectsCreate(name: string): string =
  ## Create a new project named NAME.
  ## https://developer.todoist.com/rest/v8/#create-a-new-project
  let
    dataJson = %*{
      "name": name
      }
    jsonObj = getApiUrl("projects").requestPost($dataJson)
  # https://developer.todoist.com/rest/v8/#projects
  # id, name, comment_count, order, indent
  let
    id = jsonObj["id"].getInt
    name = jsonObj["name"].getStr
  result = fmt"New project created: {name} ({id})"

proc doStuff(action, data: string) =
  ## Doer proc.
  var ret: string
  ret = case action
        of "plist":
          projectsGet()
        of "pcreate":
          if data == "":
            raise newException(UserError, "New project name needs to be provided using the '-d' switch.")
          projectsCreate(data)
        else:
          projectsGet()
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
