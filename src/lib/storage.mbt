///|
#module("node:fs")
extern "js" fn read_file_sync(path : String, encoding : String) -> String = "readFileSync"

///|
#module("node:fs")
extern "js" fn write_file_sync(path : String, data : String) -> Unit = "writeFileSync"

///|
#module("node:fs")
extern "js" fn mkdir_sync(path : String, options : Value) -> Unit = "mkdirSync"

///|
#module("node:fs")
extern "js" fn exists_sync(path : String) -> Bool = "existsSync"

///|
#module("node:fs")
extern "js" fn unlink_sync(path : String) -> Unit = "unlinkSync"

///|
#module("node:path")
extern "js" fn path_join(a : String, b : String) -> String = "join"

///|
#module("node:path")
extern "js" fn dirname(path : String) -> String = "dirname"

///|
#module("node:os")
extern "js" fn homedir() -> String = "homedir"

///|
extern "js" fn make_mkdir_options() -> Value =
  #|() => ({ recursive: true })

///|
pub extern "js" fn get_today() -> String =
  #|() => new Date().toISOString().slice(0, 10)

///|
fn get_data_dir() -> String {
  let home = homedir()
  path_join(path_join(home, ".sga"), "knowledge")
}

///|
fn ensure_dir(path : String) -> Unit {
  let dir = dirname(path)
  if not(exists_sync(dir)) {
    mkdir_sync(dir, make_mkdir_options())
  }
}

///|
fn get_knowledge_path(id : String) -> String {
  let data_dir = get_data_dir()
  path_join(data_dir, id + ".md")
}

///|
pub fn save_knowledge_file(
  id : String,
  title : String,
  content : String,
  tags : Array[String]
) -> String {
  let path = get_knowledge_path(id)
  ensure_dir(path)
  let tags_str = tags.map(fn(t) { "#" + t }).join(" ")
  let date = get_today()
  let md = "---\nid: " +
    id +
    "\ntitle: " +
    title +
    "\ndate: " +
    date +
    "\ntags: " +
    tags_str +
    "\n---\n\n" +
    content
  write_file_sync(path, md)
  path
}

///|
pub fn get_knowledge_file(id : String) -> String? {
  let path = get_knowledge_path(id)
  if exists_sync(path) {
    Some(read_file_sync(path, "utf-8"))
  } else {
    None
  }
}

///|
pub fn delete_knowledge_file(id : String) -> Bool {
  let path = get_knowledge_path(id)
  if exists_sync(path) {
    unlink_sync(path)
    true
  } else {
    false
  }
}

///|
pub fn get_db_path() -> String {
  let home = homedir()
  path_join(path_join(home, ".sga"), "sga.duckdb")
}
