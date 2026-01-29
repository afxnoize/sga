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
#module("node:fs")
extern "js" fn rm_sync(path : String, options : Value) -> Unit = "rmSync"

///|
#module("node:path")
extern "js" fn path_join(a : String, b : String) -> String = "join"

///|
#module("node:path")
extern "js" fn dirname(path : String) -> String = "dirname"

///|
extern "js" fn make_mkdir_options() -> Value =
  #|() => ({ recursive: true })

///|
extern "js" fn make_rm_options() -> Value =
  #|() => ({ recursive: true, force: true })

///|
pub extern "js" fn get_today() -> String =
  #|() => new Date().toISOString().slice(0, 10)

///|
fn ensure_dir(path : String) -> Unit {
  if not(exists_sync(path)) {
    mkdir_sync(path, make_mkdir_options())
  }
}

///|
fn get_knowledge_dir(id : String) -> String {
  let config = get_config()
  path_join(config.data_dir, id)
}

///|
fn get_knowledge_path(id : String) -> String {
  let dir = get_knowledge_dir(id)
  path_join(dir, "knowledge.md")
}

///|
fn format_tags_yaml(tags : Array[String]) -> String {
  if tags.is_empty() {
    "[]"
  } else {
    let items = tags.map(fn(t) { "\n  - " + t })
    items.join("")
  }
}

///|
pub fn save_knowledge_file(
  id : String,
  title : String,
  content : String,
  tags : Array[String],
) -> String {
  let dir = get_knowledge_dir(id)
  ensure_dir(dir)
  let path = get_knowledge_path(id)
  let date = get_today()
  let tags_yaml = format_tags_yaml(tags)
  let md = "---\nid: " +
    id +
    "\ntitle: " +
    title +
    "\ndate: " +
    date +
    "\ntags:" +
    tags_yaml +
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
  let dir = get_knowledge_dir(id)
  if exists_sync(dir) {
    rm_sync(dir, make_rm_options())
    true
  } else {
    false
  }
}
