///|
fn main {
  @lib.init_db(@lib.get_db_path())
  @lib.start_mcp_server()
}
