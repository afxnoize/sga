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
  #|  version: "0.2.0"
  #|})

///|
extern "js" fn server_tool_async(
  server : Value,
  name : String,
  description : String,
  schema : Value,
  handler : (Value) -> Value,
) -> Unit =
  #|(server, name, description, schema, handler) => {
  #|  server.tool(name, description, schema, async (params) => {
  #|    try {
  #|      const result = await handler(params);
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
  #|  query: { type: "string", description: "Search query for title and content" },
  #|  tags: { type: "array", items: { type: "string" }, description: "Filter by tags" },
  #|  date_from: { type: "string", description: "Filter from date (YYYY-MM-DD)" },
  #|  date_to: { type: "string", description: "Filter to date (YYYY-MM-DD)" },
  #|  limit: { type: "number", description: "Maximum results to return" },
  #|  semantic: { type: "boolean", description: "Use semantic (vector) search instead of keyword search" }
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
extern "js" fn get_param_string_array(
  params : Value,
  key : String,
) -> Array[String]? =
  #|(params, key) => params[key] ?? null

///|
extern "js" fn get_param_int(params : Value, key : String) -> Int? =
  #|(params, key) => params[key] ?? null

///|
extern "js" fn get_param_bool(params : Value, key : String) -> Bool? =
  #|(params, key) => params[key] ?? null

///|
extern "js" fn array_to_value(arr : Array[KnowledgeMeta]) -> Value =
  #|(arr) => arr

///|
extern "js" fn make_save_result(id : String, path : String) -> Value =
  #|(id, path) => ({ id, path, success: true })

///|
extern "js" fn make_save_result_with_embedding(
  id : String,
  path : String,
  embedding_status : String,
) -> Value =
  #|(id, path, embedding_status) => ({ id, path, success: true, embedding_status })

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
extern "js" fn handle_save_with_embedding(
  id : String,
  date : String,
  title : String,
  content : String,
  tags : Array[String],
  path : String,
  embedding_promise : Value,
  insert_fn : (KnowledgeEntry) -> Unit,
  result_fn : (String, String, String) -> Value,
) -> Value =
  #|(id, date, title, content, tags, path, embedding_promise, insert_fn, result_fn) => {
  #|  return embedding_promise.then(result => {
  #|    const embedding = result.embedding || null;
  #|    const embedding_status = result.error ? "failed: " + result.error : "success";
  #|    insert_fn({ id, date, title, content, tags, path, embedding });
  #|    return result_fn(id, path, embedding_status);
  #|  });
  #|}

///|
fn handle_save(params : Value) -> Value {
  let title = get_param_string(params, "title").unwrap_or("")
  let content = get_param_string(params, "content").unwrap_or("")
  let tags = get_param_string_array(params, "tags").unwrap_or([])
  let id = generate_id()
  let path = save_knowledge_file(id, title, content, tags)
  let date = get_today()
  let embedding_promise = generate_embedding_for_content(title, content, tags)
  handle_save_with_embedding(
    id, date, title, content, tags, path, embedding_promise, insert_knowledge, make_save_result_with_embedding,
  )
}

///|
extern "js" fn handle_semantic_search_with_embedding(
  embedding_promise : Value,
  limit : Int,
  search_fn : (Array[Double], Int) -> Array[KnowledgeMeta],
  to_value_fn : (Array[KnowledgeMeta]) -> Value,
) -> Value =
  #|(embedding_promise, limit, search_fn, to_value_fn) => {
  #|  return embedding_promise.then(result => {
  #|    if (result.embedding) {
  #|      const results = search_fn(result.embedding, limit);
  #|      return to_value_fn(results);
  #|    }
  #|    return [];
  #|  });
  #|}

///|
fn handle_search(params : Value) -> Value {
  let semantic = get_param_bool(params, "semantic").unwrap_or(false)
  let query_str = get_param_string(params, "query")
  let limit = get_param_int(params, "limit").unwrap_or(100)
  if semantic {
    match query_str {
      Some(q) => {
        let embedding_promise = generate_embedding(q)
        handle_semantic_search_with_embedding(
          embedding_promise, limit, search_knowledge_semantic, array_to_value,
        )
      }
      None => array_to_value([])
    }
  } else {
    let query : SearchQuery = {
      query: query_str,
      tags: get_param_string_array(params, "tags"),
      date_from: get_param_string(params, "date_from"),
      date_to: get_param_string(params, "date_to"),
      limit: Some(limit),
      semantic: Some(false),
    }
    let results = search_knowledge(query)
    array_to_value(results)
  }
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
  server_tool_async(
    server,
    "memory_save",
    "Save a new piece of knowledge with automatic embedding generation",
    make_save_schema(),
    handle_save,
  )
  server_tool_async(
    server,
    "memory_search",
    "Search for knowledge by query, tags, or date range. Use semantic=true for vector similarity search.",
    make_search_schema(),
    handle_search,
  )
  server_tool_async(
    server,
    "memory_get",
    "Get a specific knowledge entry by ID",
    make_id_schema(),
    handle_get,
  )
  server_tool_async(
    server,
    "memory_list",
    "List all knowledge entries",
    make_empty_schema(),
    handle_list,
  )
  server_tool_async(
    server,
    "memory_delete",
    "Delete a knowledge entry by ID",
    make_id_schema(),
    handle_delete,
  )
  let transport = new_stdio_transport(transport_class)
  server_connect(server, transport)
}
