# sga 実装修正計画

## 概要

requirements.md に沿った実装修正。Ollama を使用した Embedding 実装を含む。

## 現状と要件の差分

| 項目 | 現状 | 要件 |
|------|------|------|
| ID形式 | `adj-color-animal` | `yyyy-mm-dd_adj_color_animal` |
| 保存先 | `~/.sga/knowledge/id.md` | `$XDG_DATA_HOME/agents/memory/id/knowledge.md` |
| DB | `~/.sga/sga.duckdb` | `$XDG_DATA_HOME/agents/memory.duckdb` |
| DBスキーマ | content/embeddingなし | content TEXT, embedding FLOAT[] |
| FTS | なし | content全文検索 |
| Vector検索 | なし | semantic パラメータ |
| 設定 | ハードコード | 環境変数 + CLI引数 |

## 修正タスク

### 1. ID形式変更 (src/lib/id.mbt)

```moonbit
// Before: "adj-color-animal"
// After:  "2026-01-29_adj_color_animal"
pub fn generate_id() -> String {
  let date = get_today()  // "2026-01-29"
  let adj = random_element(adjectives)
  let color = random_element(colors)
  let animal = random_element(animals)
  "\{date}_\{adj}_\{color}_\{animal}"
}
```

### 2. 設定機構追加 (src/lib/config.mbt 新規)

```moonbit
// 環境変数: XDG_DATA_HOME, SGA_DATA_DIR, SGA_DB_PATH, SGA_EMBEDDING_MODEL
// CLI引数: --data-dir, --db-path
pub struct Config {
  data_dir: String   // $XDG_DATA_HOME/agents/memory
  db_path: String    // $XDG_DATA_HOME/agents/memory.duckdb
  embedding_model: String  // ollama model name
}
```

### 3. ストレージ変更 (src/lib/storage.mbt)

ディレクトリ形式に変更:
```
memory/
└── 2026-01-29_quiet_lime_rabbit/
    ├── knowledge.md
    └── attachments/
```

- `get_data_dir()` → 設定から取得
- `get_knowledge_path(id)` → `{data_dir}/{id}/knowledge.md`
- `save_knowledge_file()` → ディレクトリ作成 + YAML配列形式tags

### 4. DBスキーマ拡張 (src/lib/db.mbt)

```sql
CREATE TABLE IF NOT EXISTS knowledge (
  id VARCHAR PRIMARY KEY,
  date DATE NOT NULL,
  title VARCHAR NOT NULL,
  content TEXT,                -- FTS用
  tags VARCHAR[],
  path VARCHAR NOT NULL,
  embedding FLOAT[],           -- Vector embedding
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

FTS/VSSインデックスはDuckDB拡張が必要（後述）

### 5. Embedding実装 (src/lib/embedding.mbt 新規)

Ollama API連携:
```
POST http://localhost:11434/api/embeddings
{ "model": "nomic-embed-text", "prompt": "..." }
```

MoonBit JS FFI で fetch API を使用。

### 6. MCP拡張 (src/lib/mcp.mbt)

- `make_search_schema()` に `semantic` パラメータ追加
- `handle_search()` でsemantic検索対応
- `handle_save()` でembedding生成を呼び出し

### 7. bin/sga.mjs 変更

CLI引数パース追加（minimist等不要、手動パース）

## 修正ファイル一覧

| ファイル | 変更内容 |
|----------|----------|
| `src/lib/id.mbt` | 日付付きID形式 |
| `src/lib/config.mbt` | 新規: 設定機構 |
| `src/lib/storage.mbt` | ディレクトリ形式 + 設定利用 |
| `src/lib/db.mbt` | スキーマ拡張 + content保存 |
| `src/lib/embedding.mbt` | 新規: Ollama連携 |
| `src/lib/mcp.mbt` | semantic検索 + embedding呼び出し |
| `src/lib/types.mbt` | Config構造体追加 |
| `src/main/main.mbt` | 設定初期化 |
| `bin/sga.mjs` | CLI引数パース |

## 実装順序

1. config.mbt (設定機構)
2. id.mbt (ID形式)
3. storage.mbt (ディレクトリ形式)
4. db.mbt (スキーマ拡張)
5. embedding.mbt (Ollama連携)
6. mcp.mbt (semantic検索)
7. main.mbt + bin/sga.mjs (統合)

## 検証方法

1. `moon build --target js` でビルド
2. MCPサーバー起動: `node bin/sga.mjs`
3. MCP Inspector または Claude Code で各ツールをテスト:
   - `memory_save` → ディレクトリ作成確認 + DB確認
   - `memory_search` (query) → FTS検索
   - `memory_search` (semantic) → Vector検索
   - `memory_get`, `memory_list`, `memory_delete`

## 注意事項

- DuckDB FTS/VSS拡張: `INSTALL fts; LOAD fts;` が必要（初回のみ）
- Ollama: `ollama pull nomic-embed-text` が事前に必要
- 既存データ: 移行スクリプトは別途対応（今回は新規として実装）

## Codex CLI Review (2026-01-29)

### Summary
- 計画/要件ドキュメントであり直接的なバグやセキュリティリスクはない
- 複数の要件が未定義で統合時にバグを引き起こす可能性あり
- 移行/テストの詳細が欠落
- 設定の優先順位やCLIパースに曖昧さあり
- セキュリティ/パフォーマンス上の懸念あり

### Findings

| 重要度 | 問題 |
|--------|------|
| medium | DuckDB FTS/VSSの使用が具体的に定義されていない（DDL、semanticマッピング不明） |
| medium | `FLOAT[]`のembedding型が曖昧。次元数の明示がないとinsert/queryが失敗する可能性 |
| medium | 「既存データ移行は別途」で既存データが孤立。後方互換性の説明なし |
| medium | Embedding API呼び出しにエラーハンドリング、タイムアウト、リトライがない |
| low | 設定の優先順位とデフォルト値が不明確 |
| low | ID生成の`get_today()`にタイムゾーン/ロケールの言及なし |
| low | 「手動パース」のCLI解析はエッジケース未定義 |
| low | contentとembeddingのサイズ制限なし、保持ポリシー未定義 |

### TODO (Review対応)
- [ ] DuckDBセットアップを明示（INSTALL/LOAD、FTSインデックス作成SQL、semanticクエリSQL）
- [ ] embedding次元数を明記（nomic-embed-text: 768次元）
- [ ] 設定優先順位を文書化（CLI > 環境変数 > XDG）
- [ ] ID生成のタイムゾーン処理を明確化（UTC使用）
- [ ] Ollama fetchにエラーハンドリング/タイムアウトを追加
- [ ] contentとembeddingにサイズ制限を定義
