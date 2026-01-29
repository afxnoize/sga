///|
extern "js" fn get_mcp_server_class() -> Value =
  #|() => globalThis.__mcp.McpServer

///|
extern "js" fn get_stdio_transport_class() -> Value =
  #|() => globalThis.__mcp.StdioServerTransport

///|
extern "js" fn new_mcp_server(server_class : Value, info : Value) -> Value =
  #|(ServerClass, info) => new ServerClass(info)

///|
extern "js" fn new_stdio_transport(transport_class : Value) -> Value =
  #|(TransportClass) => new TransportClass()

///|
extern "js" fn server_connect(server : Value, transport : Value) -> Unit =
  #|(server, transport) => server.connect(transport)

///|
extern "js" fn make_server_info() -> Value =
  #|() => ({
  #|  name: "sga",
  #|  version: "0.1.0"
  #|})

///|
extern "js" fn server_tool(
  server : Value,
  name : String,
  description : String,
  schema : Value,
  handler : (Value) -> Value
) -> Unit =
  #|(server, name, description, schema, handler) => {
  #|  server.tool(name, description, schema, async (params) => {
  #|    try {
  #|      const result = handler(params);
  #|      return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  #|    } catch (e) {
  #|      return { content: [{ type: "text", text: "Error: " + e.message }], isError: true };
  #|    }
  #|  });
  #|}

///|
extern "js" fn make_save_schema() -> Value =
  #|() => ({
  #|  title: { type: "string", description: "Title of the knowledge" },
  #|  content: { type: "string", description: "Content of the knowledge" },
  #|  tags: { type: "array", items: { type: "string" }, description: "Tags for categorization" }
  #|})

///|
extern "js" fn make_search_schema() -> Value =
  #|() => ({
  #|  query: { type: "string", description: "Search query for title" },
  #|  tags: { type: "array", items: { type: "string" }, description: "Filter by tags" },
  #|  date_from: { type: "string", description: "Filter from date (YYYY-MM-DD)" },
  #|  date_to: { type: "string", description: "Filter to date (YYYY-MM-DD)" },
  #|  limit: { type: "number", description: "Maximum results to return" }
  #|})

///|
extern "js" fn make_id_schema() -> Value =
  #|() => ({
  #|  id: { type: "string", description: "Knowledge ID" }
  #|})

///|
extern "js" fn make_empty_schema() -> Value =
  #|() => ({})

///|
extern "js" fn get_param_string(params : Value, key : String) -> String? =
  #|(params, key) => params[key] ?? null

///|
extern "js" fn get_param_string_array(params : Value, key : String) -> Array[String]? =
  #|(params, key) => params[key] ?? null

///|
extern "js" fn get_param_int(params : Value, key : String) -> Int? =
  #|(params, key) => params[key] ?? null

///|
extern "js" fn array_to_value(arr : Array[KnowledgeMeta]) -> Value =
  #|(arr) => arr

///|
extern "js" fn make_save_result(id : String, path : String) -> Value =
  #|(id, path) => ({ id, path, success: true })

///|
extern "js" fn make_get_result(meta : KnowledgeMeta, content : String) -> Value =
  #|(meta, content) => ({ ...meta, content })

///|
extern "js" fn make_not_found_result(id : String) -> Value =
  #|(id) => ({ error: "Not found", id })

///|
extern "js" fn make_delete_result(id : String, success : Bool) -> Value =
  #|(id, success) => ({ id, deleted: success })

///|
fn handle_save(params : Value) -> Value {
  let title = get_param_string(params, "title").unwrap_or("")
  let content = get_param_string(params, "content").unwrap_or("")
  let tags = get_param_string_array(params, "tags").unwrap_or([])
  let id = generate_id()
  let path = save_knowledge_file(id, title, content, tags)
  let date = get_today()
  insert_knowledge({ id, date, title, tags, path })
  make_save_result(id, path)
}

///|
fn handle_search(params : Value) -> Value {
  let query : SearchQuery = {
    query: get_param_string(params, "query"),
    tags: get_param_string_array(params, "tags"),
    date_from: get_param_string(params, "date_from"),
    date_to: get_param_string(params, "date_to"),
    limit: get_param_int(params, "limit"),
  }
  let results = search_knowledge(query)
  array_to_value(results)
}

///|
fn handle_get(params : Value) -> Value {
  let id = get_param_string(params, "id").unwrap_or("")
  match get_knowledge_meta(id) {
    Some(meta) =>
      match get_knowledge_file(id) {
        Some(content) => make_get_result(meta, content)
        None => make_not_found_result(id)
      }
    None => make_not_found_result(id)
  }
}

///|
fn handle_list(_params : Value) -> Value {
  let results = list_all_knowledge()
  array_to_value(results)
}

///|
fn handle_delete(params : Value) -> Value {
  let id = get_param_string(params, "id").unwrap_or("")
  let db_deleted = delete_knowledge_meta(id)
  let file_deleted = delete_knowledge_file(id)
  make_delete_result(id, db_deleted && file_deleted)
}

///|
pub fn start_mcp_server() -> Unit {
  let server_class = get_mcp_server_class()
  let transport_class = get_stdio_transport_class()
  let server = new_mcp_server(server_class, make_server_info())
  server_tool(
    server,
    "memory_save",
    "Save a new piece of knowledge",
    make_save_schema(),
    handle_save,
  )
  server_tool(
    server,
    "memory_search",
    "Search for knowledge by query, tags, or date range",
    make_search_schema(),
    handle_search,
  )
  server_tool(
    server,
    "memory_get",
    "Get a specific knowledge entry by ID",
    make_id_schema(),
    handle_get,
  )
  server_tool(
    server,
    "memory_list",
    "List all knowledge entries",
    make_empty_schema(),
    handle_list,
  )
  server_tool(
    server,
    "memory_delete",
    "Delete a knowledge entry by ID",
    make_id_schema(),
    handle_delete,
  )
  let transport = new_stdio_transport(transport_class)
  server_connect(server, transport)
}
