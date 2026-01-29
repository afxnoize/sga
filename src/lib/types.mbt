///|
#external
pub type Value

///|
pub struct KnowledgeMeta {
  id : String
  date : String
  title : String
  tags : Array[String]
  path : String
}

///|
pub struct SearchQuery {
  query : String?
  tags : Array[String]?
  date_from : String?
  date_to : String?
  limit : Int?
  semantic : Bool?
}

///|
pub fn SearchQuery::default() -> SearchQuery {
  {
    query: None,
    tags: None,
    date_from: None,
    date_to: None,
    limit: None,
    semantic: None,
  }
}

///|
pub struct Config {
  data_dir : String
  db_path : String
  embedding_model : String
}

///|
pub struct KnowledgeEntry {
  id : String
  date : String
  title : String
  content : String
  tags : Array[String]
  path : String
  embedding : Array[Double]?
}
