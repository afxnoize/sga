# sga - Sagittarius A*

ナレッジ管理MCPサーバー。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code                        │
└──────────────────────┬──────────────────────────────┘
                       │ MCP (stdio)
┌──────────────────────▼──────────────────────────────┐
│                 sga MCPサーバー                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │   mcp    │──│ storage  │──│    id    │          │
│  └──────────┘  └────┬─────┘  └──────────┘          │
│                     │                               │
│              ┌──────▼──────┐                        │
│              │   DuckDB    │                        │
│              │ (FTS+Vector)│                        │
│              └─────────────┘                        │
└─────────────────────────────────────────────────────┘
```

## データ保存先

```
$XDG_DATA_HOME/agents/
├── memory.duckdb                           # メタデータ + Vector Index
└── memory/
    ├── 2026-01-29_quiet_lime_rabbit/       # ディレクトリ形式
    │   ├── knowledge.md                    # 本文
    │   └── attachments/                    # 添付ファイル（画像など）
    └── 2026-01-28_happy_blue_fox/
        └── knowledge.md
```

## 設定

保存先は環境変数またはCLI引数で変更可能。優先順位: CLI引数 > 環境変数 > XDGデフォルト

### 環境変数

| 変数名 | 説明 | デフォルト |
|--------|------|-----------|
| `SGA_DATA_DIR` | memoryファイルの保存先 | `$XDG_DATA_HOME/agents/memory` |
| `SGA_DB_PATH` | DuckDBファイルのパス | `$XDG_DATA_HOME/agents/memory.duckdb` |
| `SGA_EMBEDDING_MODEL` | Ollamaの埋め込みモデル | `nomic-embed-text` |

### CLI引数

| 引数 | 説明 |
|------|------|
| `--data-dir=<path>` | memoryファイルの保存先 |
| `--db-path=<path>` | DuckDBファイルのパス |

### 使用例

```bash
# 環境変数で指定
SGA_DATA_DIR=/custom/memory SGA_DB_PATH=/custom/memory.duckdb bun bin/sga.mjs

# CLI引数で指定
bun bin/sga.mjs --data-dir=/custom/memory --db-path=/custom/memory.duckdb
```

## 開発環境

### 必要なツール

- Bun
- pnpm
- MoonBit
- [just](https://github.com/casey/just)

### devboxを使ったセットアップ（推奨）

[devbox](https://www.jetify.com/devbox)を使用すると、必要なツールが自動的にインストールされます。

```bash
# devboxシェルに入る（初回はMoonBitも自動インストール）
devbox shell

# 依存関係のインストール
just install

# ビルド
just build
```

### 手動セットアップ

```bash
# MoonBitのインストール
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash

# 依存関係のインストール
just install

# ビルド
just build
```

## 使用方法

```bash
just run
```

その他のコマンドは `just` で一覧表示。

### Claude Codeとの連携

`.claude/settings.local.json`:

```json
{
  "mcpServers": {
    "sga": {
      "command": "bun",
      "args": ["bin/sga.mjs", "--data-dir=/custom/path"],
      "cwd": "/path/to/sga"
    }
  }
}
```

## MCPツール

| ツール | 説明 |
|--------|------|
| `memory_save` | ナレッジを保存 |
| `memory_search` | FTS/Vector検索 |
| `memory_get` | IDで取得 |
| `memory_list` | 一覧取得 |
| `memory_delete` | 削除 |

## プロジェクト構成

```
sga/
├── moon.mod.json           # MoonBitモジュール設定
├── package.json            # Node.js依存
├── bin/
│   └── sga.mjs            # エントリポイント
└── src/
    ├── lib/
    │   ├── moon.pkg       # ライブラリパッケージ
    │   ├── id.mbt         # ID生成 (yyyy-mm-dd_adjective_color_animal)
    │   ├── types.mbt      # 共通型定義
    │   ├── storage.mbt    # ファイル操作
    │   ├── db.mbt         # DuckDB操作 (FTS + Vector)
    │   └── mcp.mbt        # MCPサーバー
    └── main/
        ├── moon.pkg       # メインパッケージ
        └── main.mbt       # main関数
```
