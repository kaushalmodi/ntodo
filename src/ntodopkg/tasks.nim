import strformat, strutils, json, httpclient
# import typetraits
import ./core

proc getAll(withIndex: bool = false): string =
  ## Get tasks.
  ## https://developer.todoist.com/rest/v8/#get-all-tasks
  jsonObj = getApiUrl("tasks").req(HttpGet)
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

proc action*(data, action: string): string =
  ## Task actions.
  result = case action
           of "list":
             getAll()
           else:
             getAll()
