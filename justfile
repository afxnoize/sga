set dotenv-load
set shell := ["bash", "-cu"]

default:
  @just --list

# 依存関係のインストール
install:
  pnpm install

# MoonBitビルド
build:
  moon build --target js

# MCPサーバー起動
run *args:
  bun bin/sga.mjs {{args}}

# 開発用: ビルドして実行
dev: build
  bun bin/sga.mjs

# クリーンビルド
clean:
  moon clean

# テスト
test:
  moon test

# スナップショット更新
test-update:
  moon test -u

# フォーマット
fmt:
  moon fmt

# 型定義ファイル生成
info:
  moon info

# lint
check:
  moon check

# リリース前チェック (fmt + info + check + test)
ci: fmt info check test
