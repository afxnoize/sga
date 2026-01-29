# sag 実装計画

## 概要

MoonBitでナレッジ管理MCPサーバーを実装する。Node.js向けにコンパイルし、DuckDBでメタデータを管理。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code                        │
└──────────────────────┬──────────────────────────────┘
                       │ MCP (stdio)
┌──────────────────────▼──────────────────────────────┐
│                 sag MCPサーバー                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │   mcp    │──│ storage  │──│    id    │          │
│  └──────────┘  └────┬─────┘  └──────────┘          │
│                     │                               │
│              ┌──────▼──────┐                        │
│              │   DuckDB    │                        │
│              └─────────────┘                        │
└─────────────────────────────────────────────────────┘
```

## 実装フェーズ

### Phase 1: プロジェクト基盤

**目的**: MoonBit + Node.jsプロジェクトの基盤構築

**作成ファイル**:
- `moon.mod.json` - モジュール設定
- `src/lib/moon.pkg` - ライブラリパッケージ
- `src/main/moon.pkg` - メインエントリポイント設定

**設定ポイント**:
- `"preferred-target": "js"`
- ESMフォーマット出力
- Node.js依存パッケージ: `duckdb`, `@modelcontextprotocol/sdk`

---

### Phase 2: ID生成モジュール

**ファイル**: `src/lib/id.mbt`

**実装内容**:
```moonbit
// 単語リスト (各10語)
let adjectives : Array[String] = ["quiet", "bold", "swift", ...]
let colors : Array[String] = ["lime", "azure", "coral", ...]
let animals : Array[String] = ["rabbit", "fox", "hawk", ...]

// ID生成
pub fn generate_id() -> String
```

**依存**: Math.random (JS FFI)

---

### Phase 3: ストレージモジュール

**ファイル**: `src/lib/storage.mbt`, `src/lib/db.mbt`

#### 3.1 ファイル操作 (`storage.mbt`)

```moonbit
// Node.js fs FFI
#module("node:fs")
extern "js" fn readFileSync(path : String, encoding : String) -> String

#module("node:fs")
extern "js" fn writeFileSync(path : String, data : String) -> Unit

#module("node:fs")
extern "js" fn mkdirSync(path : String, options : Value) -> Unit

// 公開API
pub fn save_knowledge(title : String, content : String, tags : Array[String]) -> String
pub fn get_knowledge(id : String) -> String?
pub fn delete_knowledge(id : String) -> Bool
```

#### 3.2 DuckDB操作 (`db.mbt`)

```moonbit
// DuckDB FFI (非同期のためPromise経由)
#external
pub type Database

#external
pub type Connection

// 初期化・クエリ
pub fn init_db(path : String) -> Unit
pub fn insert_knowledge(meta : KnowledgeMeta) -> Unit
pub fn search_knowledge(query : SearchQuery) -> Array[KnowledgeMeta]
```

**スキーマ初期化**:
```sql
CREATE TABLE IF NOT EXISTS knowledge (
  id VARCHAR PRIMARY KEY,
  date DATE NOT NULL,
  title VARCHAR NOT NULL,
  tags VARCHAR[],
  path VARCHAR NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### Phase 4: MCPサーバー

**ファイル**: `src/lib/mcp.mbt`, `src/main/main.mbt`

#### 4.1 MCPプロトコル (`mcp.mbt`)

MCP SDK (@modelcontextprotocol/sdk) をFFI経由で使用:

```moonbit
#module("@modelcontextprotocol/sdk/server/index.js")
extern "js" fn create_server() -> Value = "Server"

#module("@modelcontextprotocol/sdk/server/stdio.js")
extern "js" fn create_stdio_transport() -> Value = "StdioServerTransport"
```

#### 4.2 ツール定義

| ツール | 実装 |
|--------|------|
| `memory_save` | `save_knowledge()` 呼び出し |
| `memory_search` | `search_knowledge()` 呼び出し |
| `memory_get` | `get_knowledge()` 呼び出し |
| `memory_list` | `list_knowledge()` 呼び出し |
| `memory_delete` | `delete_knowledge()` 呼び出し |

#### 4.3 エントリポイント (`main.mbt`)

```moonbit
pub fn main() -> Unit {
  init_db(get_db_path())
  start_mcp_server()
}
```

---

## ファイル構成

```
sag/
├── moon.mod.json
├── src/
│   ├── lib/
│   │   ├── moon.pkg
│   │   ├── id.mbt          # ID生成
│   │   ├── storage.mbt     # ファイル操作
│   │   ├── db.mbt          # DuckDB操作
│   │   ├── mcp.mbt         # MCPプロトコル
│   │   └── types.mbt       # 共通型定義
│   └── main/
│       ├── moon.pkg
│       └── main.mbt        # エントリポイント
├── package.json            # Node.js依存
└── .claude/settings.json   # MCP設定例
```

---

## 依存パッケージ (package.json)

```json
{
  "type": "module",
  "dependencies": {
    "duckdb": "^1.0.0",
    "@modelcontextprotocol/sdk": "^1.0.0"
  }
}
```

## 技術選定 (確定)

| 項目 | 選択 | 理由 |
|------|------|------|
| DuckDB | Node.jsネイティブ | フル機能、高速 |
| MCP | SDK使用 | 安定、実装容易 |

---

## 検証手順

1. **ビルド確認**
   ```bash
   moon build --target js
   ```

2. **単体テスト**
   ```bash
   moon test --target js
   ```

3. **MCPサーバー起動確認**
   ```bash
   node target/js/release/build/main/main.js
   ```

4. **Claude Code連携テスト**
   - `.claude/settings.json`にMCPサーバー登録
   - `memory_save`, `memory_search`等を実行

---

## 実装順序

1. Phase 1: プロジェクト基盤 (moon.mod.json, moon.pkg)
2. Phase 2: ID生成 (id.mbt + テスト)
3. Phase 3.1: ファイル操作 (storage.mbt + テスト)
4. Phase 3.2: DuckDB操作 (db.mbt + テスト)
5. Phase 4: MCPサーバー (mcp.mbt, main.mbt)
6. 統合テスト
