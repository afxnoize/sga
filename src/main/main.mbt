///|
fn main {
  let config = @lib.init_config()
  @lib.init_db(config.db_path)
  @lib.start_mcp_server()
}
