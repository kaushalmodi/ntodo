# Todoist API REST v8
# http://doist.github.io/todoist-api/rest/v8

import os, options, httpclient, json, strutils, strformat, typetraits

const
  tokenFileName = ".todoist-token"
  apiBaseUrl = "https://beta.todoist.com/API/v8"

var
  client: Option[HttpClient]

proc getToken(): string =
  ## Get Todoist API token
  return tokenFileName.readFile().strip()

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

proc getJson(url: string): JsonNode =
  ## Get JSON object from URL.
  try:
    return getClient().getContent(url).parseJson()
  except:
    echo "Error: Unable to get contents from " & url
    return "[]".parseJson()

proc getProjects(): string =
  ## Get Todoist projects.
  let
    jsonObj = getApiUrl("projects").getJson()
  result = "Projects:\n\n"
  for proj in jsonObj:
    # https://developer.todoist.com/rest/v8/#get-a-project
    # id, name, comment_count, order, indent
    let
      indent = " ".repeat(proj["indent"].getInt)
      id = proj["id"].getInt
      name = proj["name"].getStr
    result = result & fmt"{indent}{name} ({id})" & "\n"

proc doStuff(user, project: string, action: char) =
  ## Doer proc.
  var ret: string
  ret = case action
        of 'p':
          getProjects()
#       of 'd':
#         getDownloads(user, project)
  #       of 't':
  #         getLatestTag(user, project)
        else:
          getProjects()
  echo ret

proc main*(user = "kaushalmodi", project: string, action: char = 'p') =
  ## Main proc.
  try:
    doStuff(user, project, action)
  except:
    echo "Error happened: " & getCurrentExceptionMsg()

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
