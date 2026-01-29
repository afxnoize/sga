///|
#external
pub type Database

///|
#external
pub type Connection

///|
extern "js" fn duckdb_database() -> Value =
  #|() => globalThis.__duckdb.Database

///|
extern "js" fn new_database(db_class : Value, path : String) -> Database =
  #|(Database, path) => new Database(path)

///|
extern "js" fn db_connect(db : Database) -> Connection =
  #|(db) => db.connect()

///|
extern "js" fn conn_run(conn : Connection, sql : String) -> Unit =
  #|(conn, sql) => conn.run(sql)

///|
extern "js" fn conn_all(conn : Connection, sql : String) -> Value =
  #|(conn, sql) => conn.all(sql)

///|
extern "js" fn value_length(v : Value) -> Int =
  #|(v) => v.length

///|
extern "js" fn value_get(v : Value, idx : Int) -> Value =
  #|(v, idx) => v[idx]

///|
extern "js" fn value_get_string(v : Value, key : String) -> String =
  #|(v, key) => v[key]

///|
extern "js" fn value_get_array(v : Value, key : String) -> Value =
  #|(v, key) => v[key] || []

///|
extern "js" fn value_to_string_array(v : Value) -> Array[String] =
  #|(v) => Array.from(v || [])

///|
let db_ref : Ref[Database?] = Ref::new(None)

///|
let conn_ref : Ref[Connection?] = Ref::new(None)

///|
pub fn init_db(path : String) -> Unit {
  let db_class = duckdb_database()
  let db = new_database(db_class, path)
  let conn = db_connect(db)
  db_ref.val = Some(db)
  conn_ref.val = Some(conn)
  let schema = "CREATE TABLE IF NOT EXISTS knowledge (id VARCHAR PRIMARY KEY, date DATE NOT NULL, title VARCHAR NOT NULL, tags VARCHAR[], path VARCHAR NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
  conn_run(conn, schema)
}

///|
fn get_conn() -> Connection {
  match conn_ref.val {
    Some(c) => c
    None => abort("Database not initialized")
  }
}

///|
extern "js" fn tags_to_sql_array(tags : Array[String]) -> String =
  #|(tags) => "[" + tags.map(t => "'" + t.replace(/'/g, "''") + "'").join(", ") + "]"

///|
extern "js" fn escape_sql_string(s : String) -> String =
  #|(s) => s.replace(/'/g, "''")

///|
pub fn insert_knowledge(meta : KnowledgeMeta) -> Unit {
  let conn = get_conn()
  let id = escape_sql_string(meta.id)
  let date = escape_sql_string(meta.date)
  let title = escape_sql_string(meta.title)
  let path = escape_sql_string(meta.path)
  let tags_sql = tags_to_sql_array(meta.tags)
  let sql = "INSERT INTO knowledge (id, date, title, tags, path) VALUES ('" +
    id +
    "', '" +
    date +
    "', '" +
    title +
    "', " +
    tags_sql +
    ", '" +
    path +
    "') ON CONFLICT (id) DO UPDATE SET date = EXCLUDED.date, title = EXCLUDED.title, tags = EXCLUDED.tags, path = EXCLUDED.path, updated_at = CURRENT_TIMESTAMP"
  conn_run(conn, sql)
}

///|
pub fn search_knowledge(query : SearchQuery) -> Array[KnowledgeMeta] {
  let conn = get_conn()
  let conditions : Array[String] = []
  match query.query {
    Some(q) => {
      let escaped = escape_sql_string(q)
      conditions.push("(title ILIKE '%" + escaped + "%')")
    }
    None => ()
  }
  match query.tags {
    Some(tags) =>
      for tag in tags {
        let escaped = escape_sql_string(tag)
        conditions.push("list_contains(tags, '" + escaped + "')")
      }
    None => ()
  }
  match query.date_from {
    Some(d) => {
      let escaped = escape_sql_string(d)
      conditions.push("date >= '" + escaped + "'")
    }
    None => ()
  }
  match query.date_to {
    Some(d) => {
      let escaped = escape_sql_string(d)
      conditions.push("date <= '" + escaped + "'")
    }
    None => ()
  }
  let where_clause = if conditions.is_empty() {
    ""
  } else {
    " WHERE " + conditions.join(" AND ")
  }
  let limit_clause = match query.limit {
    Some(n) => " LIMIT " + n.to_string()
    None => " LIMIT 100"
  }
  let sql = "SELECT id, date, title, tags, path FROM knowledge" +
    where_clause +
    " ORDER BY date DESC" +
    limit_clause
  let rows = conn_all(conn, sql)
  let result : Array[KnowledgeMeta] = []
  for i in 0..<value_length(rows) {
    let row = value_get(rows, i)
    result.push(
      {
        id: value_get_string(row, "id"),
        date: value_get_string(row, "date"),
        title: value_get_string(row, "title"),
        tags: value_to_string_array(value_get_array(row, "tags")),
        path: value_get_string(row, "path"),
      },
    )
  }
  result
}

///|
pub fn get_knowledge_meta(id : String) -> KnowledgeMeta? {
  let conn = get_conn()
  let escaped = escape_sql_string(id)
  let sql = "SELECT id, date, title, tags, path FROM knowledge WHERE id = '" +
    escaped +
    "'"
  let rows = conn_all(conn, sql)
  if value_length(rows) > 0 {
    let row = value_get(rows, 0)
    Some(
      {
        id: value_get_string(row, "id"),
        date: value_get_string(row, "date"),
        title: value_get_string(row, "title"),
        tags: value_to_string_array(value_get_array(row, "tags")),
        path: value_get_string(row, "path"),
      },
    )
  } else {
    None
  }
}

///|
pub fn delete_knowledge_meta(id : String) -> Bool {
  let conn = get_conn()
  let escaped = escape_sql_string(id)
  let sql = "DELETE FROM knowledge WHERE id = '" + escaped + "'"
  conn_run(conn, sql)
  true
}

///|
pub fn list_all_knowledge() -> Array[KnowledgeMeta] {
  search_knowledge(SearchQuery::default())
}
