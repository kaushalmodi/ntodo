import httpclient, json, random, strutils, strformat, options
import ./globals
export globals

var
  bodyDebug: string

proc getToken*(): string =
  ## Get Todoist API token.
  if isNone(token):
    token = some(tokenFileName.readFile().strip())
  return get(token)

proc getUuid*(): string =
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

proc getClient*(): HttpClient =
  ## Create a new http client if one doesn't already exist.
  if isNone(client):
    var c = newHttpClient()
    c.headers = newHttpHeaders({ "Authorization" : "Bearer " & getToken() })
    client = some(c)
  return get(client)

proc getApiUrl*(cmd: string): string =
  ## Get the full API URL for a command.
  return apiBaseUrl & "/" & cmd

proc req*(url: string, mthd: HttpMethod, data = ""): JsonNode =
  ## Get JSON object returned from URL using MTHD HTTP method.
  doAssert mthd in {HttpGet, HttpPost, HttpDelete}
  try:
    let c = getClient()
    if mthd in {HttpPost}:
      c.headers.add("Content-Type", "application/json")
      c.headers.add("X-Request-Id", getUuid())
    let
      resp = c.request(url, httpMethod = mthd, body = data)
      body = resp.body
      bodyJson = if body == "":
                   "[]"         # empty Json
                 else:
                   body
    bodyDebug = body
    return bodyJson.parseJson()
  except:
    echo fmt"[Error: req] {getCurrentException().name}: {getCurrentException().msg}" & "\n" &
      fmt"             Sent data: `{data}'" & "\n" &
      fmt"             Response body: `{bodyDebug}'"
    return "[]".parseJson()
