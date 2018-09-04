import options, json, httpclient

type
  UserError* = object of Exception
  Priority* = range[1 .. 4]

const
  tokenFileName* = ".todoist-token"
  apiBaseUrl* = "https://beta.todoist.com/API/v8"
  defaultPriority*: Priority = 4 ## Default priority when creating tasks
  defaultDueLang* = "en"         ## Default language to be used for parsing "due string" when creating tasks

var
  jsonObj*: JsonNode
  client*: Option[HttpClient]
  token*: Option[string]
