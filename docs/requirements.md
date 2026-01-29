# sga - Knowledge Management System

Claude Code用のナレッジ管理システム（MoonBit実装）

## 概要

作業内容をナレッジとして保存し、DuckDBでインデックス化。Claude Codeまたはユーザーが気になったとき、検索して該当ディレクトリの知識を参照できるシステム。

## 機能要件

| 機能 | 説明 |
|------|------|
| **保存** | ナレッジをディレクトリ形式で`$XDG_DATA_HOME/agents/memory/yyyy-mm-dd_id/`に保存 |
| **ID生成** | `yyyy-mm-dd_adjective_color_animal`形式のhuman-readable ID |
| **インデックス** | DuckDBでメタデータ + vector index を管理 |
| **FTS検索** | キーワードによる全文検索 |
| **Vector検索** | embeddingによるセマンティック類似検索 |
| **添付ファイル** | 画像・データファイルなどを添付可能 |

## 技術仕様

| 項目 | 選択 |
|------|------|
| 言語 | MoonBit → JS (Node.js) |
| MCPサーバー | Pure MoonBit + FFI |
| データベース | DuckDB (FTS + VSS拡張) |
| Embedding | 外部API（Claude API等） |

## ディレクトリ構成

### データ保存先

```
$XDG_DATA_HOME/agents/
├── memory.duckdb                          # メタデータ + Vector Index
└── memory/
    ├── 2026-01-29_quiet_lime_rabbit/
    │   ├── knowledge.md                   # 本文
    │   └── attachments/                   # 添付ファイル（任意）
    │       ├── screenshot.png
    │       └── data.json
    └── 2026-01-29_bold_azure_fox/
        └── knowledge.md
```

### プロジェクト構成

```
sga/
├── src/
│   ├── id/         # Human-readable ID生成
│   ├── storage/    # ファイル・DuckDB操作
│   ├── mcp/        # MCPプロトコル実装
│   └── main/       # エントリポイント
├── moon.mod.json
└── .claude/skills/ # Claude Code用Skills定義
```

## Human-Readable ID

### 形式

`yyyy-mm-dd_adjective_color_animal`

日付とword-based identifierを組み合わせた形式。

### 例

- `2026-01-29_quiet_lime_rabbit`
- `2026-01-28_bold_azure_fox`
- `2026-01-27_swift_coral_hawk`

### 単語リスト（最小構成）

**Adjectives**: quiet, bold, swift, calm, bright, gentle, wild, keen, soft, sharp

**Colors**: lime, azure, coral, amber, jade, ruby, ivory, onyx, pearl, teal

**Animals**: rabbit, fox, hawk, wolf, bear, deer, owl, crow, swan, lynx

## ナレッジフォーマット

### ディレクトリ構造

```
2026-01-29_quiet_lime_rabbit/
├── knowledge.md      # 必須: 本文
└── attachments/      # 任意: 添付ファイル
    ├── screenshot.png
    └── data.json
```

### knowledge.md

```markdown
---
id: 2026-01-29_quiet_lime_rabbit
date: 2026-01-29
title: タイトル
tags:
  - tag1
  - tag2
---

# 内容

本文...
```

## DuckDBスキーマ

### 保存先

`$XDG_DATA_HOME/agents/memory.duckdb`

### 初期化

```sql
INSTALL fts;
LOAD fts;
INSTALL vss;
LOAD vss;
```

### knowledge テーブル

```sql
CREATE TABLE knowledge (
  id VARCHAR PRIMARY KEY,        -- e.g., '2026-01-29_quiet_lime_rabbit'
  date DATE NOT NULL,            -- e.g., '2026-01-29'
  title VARCHAR NOT NULL,
  content TEXT,                  -- 本文（FTS用）
  tags VARCHAR[],
  path VARCHAR NOT NULL,         -- ディレクトリパス
  embedding FLOAT[1536],         -- Vector embedding
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_date ON knowledge(date);
CREATE INDEX idx_embedding ON knowledge USING HNSW(embedding);
```

### 全文検索インデックス

```sql
PRAGMA create_fts_index('knowledge', 'id', 'title', 'content');
```

## MCPツール

| ツール名 | 説明 | パラメータ |
|----------|------|-----------|
| `memory_save` | ナレッジを保存 | `title`, `content`, `tags?`, `attachments?` |
| `memory_search` | 検索 | `query?`, `tags?`, `date_from?`, `date_to?`, `semantic?` |
| `memory_get` | IDで取得 | `id` |
| `memory_list` | 一覧取得 | `limit?`, `offset?` |
| `memory_delete` | 削除 | `id` |

### memory_search 詳細

| パラメータ | 型 | 説明 |
|-----------|-----|------|
| `query` | string? | キーワード検索（FTS） |
| `tags` | string[]? | タグでフィルタ |
| `date_from` | string? | 開始日（yyyy-mm-dd） |
| `date_to` | string? | 終了日（yyyy-mm-dd） |
| `semantic` | string? | セマンティック検索クエリ（Vector検索） |
| `limit` | int? | 結果件数制限（デフォルト: 10） |

## Embedding生成

### 方式

外部APIを使用してembeddingを生成:
- Claude API (Voyager)
- OpenAI API (text-embedding-3-small)
- ローカルモデル

### タイミング

- `memory_save` 時に非同期でembedding生成
- 本文 + タイトルを連結してembedding化

## Skills連携

### /knowledge スキル

既存の`/knowledge`スキルの出力をそのままMCPサーバー経由で保存できるようにする。

## 設定

### コマンドライン引数

```bash
node bin/sga.mjs [options]
```

| 引数 | 説明 |
|------|------|
| `--data-dir <path>` | データ保存先ディレクトリ |
| `--db-path <path>` | DuckDBファイルパス |

### 環境変数

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `XDG_DATA_HOME` | `~/.local/share` | データ保存先のベース |
| `SGA_DATA_DIR` | `$XDG_DATA_HOME/agents/memory` | データ保存先（引数で上書き可） |
| `SGA_DB_PATH` | `$XDG_DATA_HOME/agents/memory.duckdb` | DuckDBパス（引数で上書き可） |
| `SGA_EMBEDDING_API` | - | Embedding API種別 |
| `SGA_EMBEDDING_KEY` | - | APIキー |

### 優先順位

1. コマンドライン引数
2. 環境変数
3. デフォルト値

### Claude Code設定例

```json
{
  "mcpServers": {
    "sga": {
      "command": "node",
      "args": ["bin/sga.mjs", "--data-dir", "/custom/memory"],
      "cwd": "/path/to/sga
    }
  }
}
```

## 参考リンク

- [MoonBit Docs](https://docs.moonbitlang.com)
- [DuckDB Docs](https://duckdb.org/docs/)
- [DuckDB FTS](https://duckdb.org/docs/extensions/full_text_search)
- [DuckDB VSS](https://duckdb.org/docs/extensions/vss)
- [MCP Protocol](https://modelcontextprotocol.io/)
