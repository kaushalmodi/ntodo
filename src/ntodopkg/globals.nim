import options, json, httpclient

const
  tokenFileName* = ".todoist-token"
  apiBaseUrl* = "https://beta.todoist.com/API/v8"

var
  jsonObj*: JsonNode
  client*: Option[HttpClient]
  token*: Option[string]

type
  UserError* = object of Exception
