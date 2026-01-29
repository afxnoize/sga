///|
test "SearchQuery::default returns all None fields" {
  let q = SearchQuery::default()
  inspect(q.query, content="None")
  inspect(q.tags, content="None")
  inspect(q.date_from, content="None")
  inspect(q.date_to, content="None")
  inspect(q.limit, content="None")
  inspect(q.semantic, content="None")
}

///|
test "KnowledgeMeta can be constructed" {
  let meta : KnowledgeMeta = {
    id: "2026-01-29_quiet_lime_rabbit",
    date: "2026-01-29",
    title: "Test Title",
    tags: ["tag1", "tag2"],
    path: "/path/to/knowledge.md",
  }
  inspect(meta.id, content="2026-01-29_quiet_lime_rabbit")
  inspect(meta.date, content="2026-01-29")
  inspect(meta.title, content="Test Title")
  inspect(meta.tags.length(), content="2")
  inspect(meta.path, content="/path/to/knowledge.md")
}

///|
test "KnowledgeEntry can be constructed with embedding" {
  let entry : KnowledgeEntry = {
    id: "2026-01-29_bold_azure_fox",
    date: "2026-01-29",
    title: "Entry Title",
    content: "Some content here",
    tags: ["moonbit", "test"],
    path: "/path/to/file.md",
    embedding: Some([0.1, 0.2, 0.3]),
  }
  inspect(entry.id, content="2026-01-29_bold_azure_fox")
  inspect(entry.content, content="Some content here")
  match entry.embedding {
    Some(emb) => inspect(emb.length(), content="3")
    None => fail("Expected embedding to be Some")
  }
}

///|
test "KnowledgeEntry can be constructed without embedding" {
  let entry : KnowledgeEntry = {
    id: "2026-01-29_swift_coral_hawk",
    date: "2026-01-29",
    title: "No Embedding",
    content: "Content without embedding",
    tags: Array::new(),
    path: "/path/to/file.md",
    embedding: None,
  }
  inspect(entry.embedding, content="None")
  inspect(entry.tags.length(), content="0")
}

///|
test "Config can be constructed" {
  let config : Config = {
    data_dir: "/home/user/.local/share/agents/memory",
    db_path: "/home/user/.local/share/agents/memory.duckdb",
    embedding_model: "nomic-embed-text",
  }
  inspect(config.data_dir, content="/home/user/.local/share/agents/memory")
  inspect(
    config.db_path,
    content="/home/user/.local/share/agents/memory.duckdb",
  )
  inspect(config.embedding_model, content="nomic-embed-text")
}
