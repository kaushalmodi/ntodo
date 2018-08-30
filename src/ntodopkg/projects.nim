import strformat, strutils, json, httpclient
import typetraits
import ./core

proc getAll(withIndex: bool = false): string =
  ## Get projects.
  ## https://developer.todoist.com/rest/v8/#get-all-projects
  jsonObj = getApiUrl("projects").req(HttpGet)
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

proc get(idx: int): string =
  ## Get a project.
  ## https://developer.todoist.com/rest/v8/#get-a-project
  doAssert jsonObj.isNil() == false
  let
    projId = jsonObj[idx]["id"].getInt()
  jsonObj = getApiUrl("projects/" & $projId).req(HttpGet)
  let
    id = jsonObj["id"].getInt()
    name = jsonObj["name"].getStr()
  result = "\n" & fmt"Selected project: {name} ({id})"

proc create(name: string): string =
  ## Create a new project named NAME.
  ## https://developer.todoist.com/rest/v8/#create-a-new-project
  let
    dataJson = %*{
      "name": name
      }
  jsonObj = getApiUrl("projects").req(HttpPost, $dataJson)
  let
    id = jsonObj["id"].getInt()
    name = jsonObj["name"].getStr()
  result = fmt"New project created: {name} ({id})"

proc rename(idx: int, name: string): string =
  ## Rename the IDX referenced project's name to NAME.
  ## https://developer.todoist.com/rest/v8/#update-a-project
  doAssert jsonObj.isNil() == false
  let
    projId = jsonObj[idx]["id"].getInt()
    oldName = jsonObj[idx]["name"].getStr()
    dataJson = %*{
      "name": name
      }
  discard getApiUrl("projects/" & $projId).req(HttpPost, $dataJson)
  result = "\n" & fmt"Renamed project ({projId}) from ‘{oldName}’ to ‘{name}’"

proc delete(idx: int): string =
  ## Delete the IDX referenced project.
  ## https://developer.todoist.com/rest/v8/#delete-a-project
  doAssert jsonObj.isNil() == false
  let
    projId = jsonObj[idx]["id"].getInt()
    name = jsonObj[idx]["name"].getStr()
  discard getApiUrl("projects/" & $projId).req(HttpDelete)
  result = "\n" & fmt"Deleted project: {name} ({projId})"

proc action*(data, action: string): string =
  ## Project actions.
  result = case action
           of "list":
             getAll()
           of "get":
             echo getAll(withIndex = true)
             stdout.write("Type the project index (number in the first column) that you need to get: ")
             let
               idx = readLine(stdin).strip().parseInt()
             get(idx)
           of "create":
             if data == "":
               raise newException(UserError, "New project name needs to be provided using the '-d' switch.")
             create(data)
           of "rename":
             echo getAll(withIndex = true)
             stdout.write("Type the project index (number in the first column) that you want to rename: ")
             let
               idx = readLine(stdin).strip().parseInt()
             stdout.write(fmt"Type the new name for the project at index {idx}: ")
             let
               name = readLine(stdin).strip()
             rename(idx, name)
           of "delete":
             echo getAll(withIndex = true)
             stdout.write("Type the project index (number in the first column) that you need to DELETE: ")
             let
               idx = readLine(stdin).strip().parseInt()
             delete(idx)
           else:
             getAll()
