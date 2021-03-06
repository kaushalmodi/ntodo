import std/[strformat, strutils, json, httpcore]
import core

const
  urlPart = "projects"

proc getAll(withIndex: bool = false): string =
  ## Get projects.
  ## https://developer.todoist.com/rest/v8/#get-all-projects
  jsonObj = getApiUrl(urlPart).req(HttpGet)
  doAssert jsonObj.isNil() == false
  var
    idx = 0
  result = "Projects:\n\n"
  for proj in jsonObj:
    # https://developer.todoist.com/rest/v8/#projects
    # id, name, comment_count, order, indent
    let
      idxString = if withIndex:
                    fmt"{idx:>4}. "
                  else:
                    "  "
      order = proj["order"].getInt()
      indent = "  ".repeat(proj["indent"].getInt() - 1)
      id = proj["id"].getInt()
      name = proj["name"].getStr()
    # echo fmt"order ({$order.type}) = {order}"
    # echo fmt"idx ({$idx.type}) = {idx}"
    doAssert idx == order
    result = result & fmt"{idxString}{indent}{name} ({id})" & "\n"
    idx += 1

proc getJson*(str = ""): JsonNode =
  ## Display a list of all project names and prompt user to pick an index.
  ## Returns the picked project's JSON object.
  echo getAll(withIndex = true)
  # Above `getAll` call populates the global var `jsonObj`.
  stdout.write("Type the project index number (first column)" & str & ": ")
  let
    idx = readLine(stdin).strip().parseInt()
  return jsonObj[idx]

proc get(id: int): string =
  ## Get a project associated with id ID.
  ## https://developer.todoist.com/rest/v8/#get-a-project
  let
    jsonObj = getApiUrl(urlPart & "/" & $id).req(HttpGet)
  doAssert jsonObj.isNil() == false
  let
    idLocal = jsonObj["id"].getInt()
    nameLocal = jsonObj["name"].getStr()
  result = "\n" & fmt"Selected project: {nameLocal} ({idLocal})"

proc create(name: string): string =
  ## Create a new project named NAME.
  ## https://developer.todoist.com/rest/v8/#create-a-new-project
  let
    dataJson = %*
      {
        "name": name
      }
  jsonObj = getApiUrl(urlPart).req(HttpPost, $dataJson)
  doAssert jsonObj.isNil() == false
  let
    id = jsonObj["id"].getInt()
    name = jsonObj["name"].getStr()
  result = fmt"New project created: {name} ({id})"

proc rename(obj: JsonNode, name: string): string =
  ## Rename the project with JSON object OBJ to NAME.
  ## https://developer.todoist.com/rest/v8/#update-a-project
  let
    id = obj["id"].getInt()
    oldName = obj["name"].getStr()
    dataJson = %*
      {
        "name": name
      }
    jsonObj = getApiUrl(urlPart & "/" & $id).req(HttpPost, $dataJson)
  doAssert jsonObj.isNil() == false
  result = "\n" & fmt"Renamed project ({id}) from ‘{oldName}’ to ‘{name}’"

proc delete(obj: JsonNode): string =
  ## Delete the project with JSON object OBJ.
  ## https://developer.todoist.com/rest/v8/#delete-a-project
  let
    id = obj["id"].getInt()
    name = obj["name"].getStr()
    jsonObj = getApiUrl(urlPart & "/" & $id).req(HttpDelete)
  doAssert jsonObj.isNil() == false
  result = "\n" & fmt"Deleted project: {name} ({id})"

proc action*(data, action: string): string =
  ## Project actions.
  result =
    case action
    of "list":
      getAll()
    of "get":
      let id = getJson(" that you need to get")["id"].getInt()
      get(id)
    of "create":
      if data == "":
        raise newException(UserError, "New project name needs to be provided using the '-d' switch.")
      create(data)
    of "rename":
      let
        obj = getJson(" that you want to rename")
        id = obj["id"].getInt()
      stdout.write(fmt"Type the new name for the project at index {id}: ")
      let
        name = readLine(stdin).strip()
      rename(obj, name)
    of "delete":
      delete(getJson(" that you need to DELETE"))
    else:
      getAll()
