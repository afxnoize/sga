///|
#module("node:os")
extern "js" fn config_homedir() -> String = "homedir"

///|
#module("node:path")
extern "js" fn config_path_join(a : String, b : String) -> String = "join"

///|
extern "js" fn get_env(name : String) -> String? =
  #|(name) => process.env[name] ?? null

///|
extern "js" fn get_cli_arg(name : String) -> String? =
  #|(name) => {
  #|  const args = process.argv.slice(2);
  #|  const prefix = "--" + name + "=";
  #|  for (const arg of args) {
  #|    if (arg.startsWith(prefix)) {
  #|      return arg.slice(prefix.length);
  #|    }
  #|  }
  #|  return null;
  #|}

///|
let config_ref : Ref[Config?] = Ref::new(None)

///|
fn get_xdg_data_home() -> String {
  match get_env("XDG_DATA_HOME") {
    Some(path) => path
    None => {
      let home = config_homedir()
      config_path_join(config_path_join(home, ".local"), "share")
    }
  }
}

///|
fn get_default_data_dir() -> String {
  let xdg = get_xdg_data_home()
  config_path_join(config_path_join(xdg, "agents"), "memory")
}

///|
fn get_default_db_path() -> String {
  let xdg = get_xdg_data_home()
  config_path_join(config_path_join(xdg, "agents"), "memory.duckdb")
}

///|
pub fn init_config() -> Config {
  // Priority: CLI > SGA_* env > XDG default
  let data_dir = match get_cli_arg("data-dir") {
    Some(v) => v
    None =>
      match get_env("SGA_DATA_DIR") {
        Some(v) => v
        None => get_default_data_dir()
      }
  }
  let db_path = match get_cli_arg("db-path") {
    Some(v) => v
    None =>
      match get_env("SGA_DB_PATH") {
        Some(v) => v
        None => get_default_db_path()
      }
  }
  let embedding_model = match get_env("SGA_EMBEDDING_MODEL") {
    Some(v) => v
    None => "nomic-embed-text"
  }
  let config : Config = { data_dir, db_path, embedding_model }
  config_ref.val = Some(config)
  config
}

///|
pub fn get_config() -> Config {
  match config_ref.val {
    Some(c) => c
    None => abort("Config not initialized")
  }
}
