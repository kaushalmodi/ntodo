import strformat, strutils, json
import ./globals, ./core

proc getAll(withIndex: bool = false): string =
  ## Get projects.
  ## https://developer.todoist.com/rest/v8/#get-all-projects
  jsonObj = getApiUrl("projects").requestGet()
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
  let
    projId = jsonObj[idx]["id"].getInt()
  jsonObj = getApiUrl("projects/" & $projId).requestGet()
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
  jsonObj = getApiUrl("projects").requestPost($dataJson)
  let
    id = jsonObj["id"].getInt()
    name = jsonObj["name"].getStr()
  result = fmt"New project created: {name} ({id})"

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
           else:
             getAll()
