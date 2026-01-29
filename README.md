# sga
SagittariusA

MoonBitで実装されたナレッジ管理MCPサーバー。

詳細な要件は [docs/requirements.md](docs/requirements.md) を参照。

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

## 開発環境

### 必要なツール

- Node.js 22
- pnpm
- MoonBit

### devboxを使ったセットアップ（推奨）

[devbox](https://www.jetify.com/devbox)を使用すると、必要なツールが自動的にインストールされます。

```bash
# devboxシェルに入る（初回はMoonBitも自動インストール）
devbox shell

# 依存関係のインストール
pnpm install

# ビルド
moon build --target js
```

### 手動セットアップ

```bash
# MoonBitのインストール
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash

# 依存関係のインストール
pnpm install

# ビルド
moon build --target js
```

## 使用方法

```bash
node bin/sga.mjs
```

### Claude Codeとの連携

`.claude/settings.local.json`:

```json
{
  "mcpServers": {
    "sga": {
      "command": "node",
      "args": ["bin/sga.mjs", "--data-dir", "/custom/path"],
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
