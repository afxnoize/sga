///|
extern "js" fn generate_embedding_js(
  url : String,
  model : String,
  text : String,
  timeout_ms : Int,
) -> Value =
  #|(url, model, text, timeout_ms) => {
  #|  const controller = new AbortController();
  #|  const timeoutId = setTimeout(() => controller.abort(), timeout_ms);
  #|  return fetch(url, {
  #|    method: "POST",
  #|    headers: { "Content-Type": "application/json" },
  #|    body: JSON.stringify({ model, prompt: text }),
  #|    signal: controller.signal
  #|  }).then(response => {
  #|    clearTimeout(timeoutId);
  #|    if (!response.ok) {
  #|      return { error: `HTTP ${response.status}: ${response.statusText}` };
  #|    }
  #|    return response.json();
  #|  }).then(data => {
  #|    if (data.error) return data;
  #|    if (data.embedding) {
  #|      return { embedding: data.embedding };
  #|    }
  #|    return { error: "No embedding in response" };
  #|  }).catch(e => {
  #|    clearTimeout(timeoutId);
  #|    if (e.name === "AbortError") {
  #|      return { error: "Request timeout" };
  #|    }
  #|    return { error: e.message };
  #|  });
  #|}

///|
pub fn generate_embedding(text : String) -> Value {
  let config = get_config()
  let url = "http://localhost:11434/api/embeddings"
  let timeout_ms = 30000
  generate_embedding_js(url, config.embedding_model, text, timeout_ms)
}

///|
extern "js" fn truncate_string(s : String, max_len : Int) -> String =
  #|(s, max_len) => s.length > max_len ? s.slice(0, max_len) : s

///|
pub fn generate_embedding_for_content(
  title : String,
  content : String,
  tags : Array[String],
) -> Value {
  let tags_str = tags.join(", ")
  let combined = "Title: " +
    title +
    "\nTags: " +
    tags_str +
    "\nContent: " +
    content
  let text = truncate_string(combined, 8000)
  generate_embedding(text)
}
