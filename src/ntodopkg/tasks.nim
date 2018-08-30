import strformat, strutils, json, httpclient
# import typetraits
import ./core
import ./projects as p

const
  urlPart = "tasks"

proc getAll(withIndex: bool = false): string =
  ## Get tasks.
  ## https://developer.todoist.com/rest/v8/#get-all-tasks
  jsonObj = getApiUrl(urlPart).req(HttpGet)
  var
    idx = 0
  result = "Tasks:\n\n"
  for proj in jsonObj:
    # https://developer.todoist.com/rest/v8/#tasks
    # id, project_id, content, comment_count, order, indent, priority, url
    let
      idxString = if withIndex:
                    fmt"{idx:>4}. "
                  else:
                    "  "
      id = proj["id"].getInt()
      project_id = proj["project_id"].getInt()
      content = proj["content"].getStr()
      comment_count = proj["comment_count"].getInt()
      commentCountString = if comment_count > 0:
                             fmt", comments: {comment_count}"
                           else:
                             ""
      # order = proj["order"].getInt()
      indent = "  ".repeat(proj["indent"].getInt() - 1)
      priority = proj["priority"].getInt()
      url = proj["url"].getStr()
    result = result & fmt"{idxString}{indent}{content} [ {priority} ]" & "\n" &
      fmt"      {indent}| p{project_id}, t{id}{commentCountString}" & "\n" &
      fmt"      {indent}| {url}" & "\n\n"
    idx += 1

proc create(content, due: string, priority: Priority, inInbox: bool): string =
  ## Create a new task named NAME in "Inbox".
  ## https://developer.todoist.com/rest/v8/#create-a-new-task
  var
    dataJson: JsonNode
    projJson: JsonNode
    projName = "Inbox"
  if inInbox:
    dataJson = %*
      {
        "content": content,
        "due_string": due,
        "due_lang": defaultDueLang,
        "priority": priority
      }
  else:
    projJson = p.getJson(" where you want to create this task")
    projName = projJson["name"].getStr()
    dataJson = %*
      {
        "content": content,
        "due_string": due,
        "due_lang": defaultDueLang,
        "priority": priority,
        "project_id": projJson["id"].getInt()
      }
  # echo dataJson.pretty()
  jsonObj = getApiUrl(urlPart).req(HttpPost, $dataJson)
  doAssert jsonObj.isNil() == false
  # echo jsonObj.pretty()
  let
    content = jsonObj["content"].getStr()
    due_string = jsonObj["due"]["string"].getStr()
    priority = jsonObj["priority"].getInt()
  result = fmt"Task created in {projName}: “{content}”, priority {priority}, due {due_string}"

proc action*(data, action: string): string =
  ## Task actions.
  result = case action
           of "list":
             getAll()
           of "create":
             stdout.write("Task: ")
             let content= readLine(stdin).strip()
             stdout.write("Task due string: ")
             let due = readLine(stdin).strip()
             stdout.write("Priority [1-4] (default=1): ")
             let
               priorityStr = readLine(stdin).strip()
               priority: Priority = if priorityStr == "":
                                      defaultPriority
                                    else:
                                      priorityStr.parseInt()
             stdout.write("Create task in Inbox? [y/n] (default=y): ")
             let
               inInboxStr = readLine(stdin).strip().toLowerAscii()
               inInbox = (inInboxStr == "") or (inInboxStr == "y")
             create(content, due, priority, inInbox)
           else:
             getAll()
