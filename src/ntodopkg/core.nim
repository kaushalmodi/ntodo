import httpclient, json, random, strutils, strformat, options
import ./globals

proc getToken*(): string =
  ## Get Todoist API token
  return tokenFileName.readFile().strip()

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
  get(client)

proc getApiUrl*(cmd: string): string =
  ## Get the full API URL for a command.
  return apiBaseUrl & "/" & cmd

proc requestGet*(url: string): JsonNode =
  ## Get JSON object returned from a GET request to URL.
  try:
    return getClient().getContent(url).parseJson()
  except:
    echo "Error: Unable to get contents from " & url
    return "[]".parseJson()

proc requestPost*(url, data: string): JsonNode =
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
