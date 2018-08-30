import httpclient, json, random, strutils, strformat, options
import ./globals
export globals

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
    client = some(newHttpClient())
  return get(client)

proc getApiUrl*(cmd: string): string =
  ## Get the full API URL for a command.
  return apiBaseUrl & "/" & cmd

proc req*(url: string, mthd: HttpMethod, data = ""): JsonNode =
  ## Get JSON object returned from URL using MTHD HTTP method.
  doAssert mthd in {HttpGet, HttpPost, HttpDelete}
  try:
    var
      c = getClient()
    if mthd in {HttpGet, HttpDelete}:
      c.headers = newHttpHeaders({ "Authorization" : "Bearer " & getToken() })
    elif mthd in {HttpPost}:
      c.headers = newHttpHeaders({ "Content-Type": "application/json",
                                   "X-Request-Id": getUuid(),
                                   "Authorization": "Bearer " & getToken() })
    let
      resp = c.request(url, httpMethod = mthd, body = data)
      body = resp.body
      bodyJson = if body == "":
                   "[]"         # empty Json
                 else:
                   body
    # echo fmt"Received body: `{resp.body}'"
    return bodyJson.parseJson()
  except:
    echo fmt"[Error req] {getCurrentException().name}: {getCurrentException().msg}"
    return "[]".parseJson()
