# 🤖 Rules for AI
<img src="https://img.shields.io/badge/LICENSE-MIT-green">

ドキュメント ([English](https://github.com/hashiiiii/rules-for-ai/blob/main/README.md), [日本語](https://github.com/hashiiiii/rules-for-ai/blob/main/README_JA.md))

## 📋 概要

Windsurf、Cursor に搭載されている AI アシスタントをより強化するためのルールセットです。
グローバル設定には事前定義された windsurf: global_rules.md / cursor: global_rules.mdc を利用します。
各ワークスペース設定には windsurf: .windsurfrules / cursor: project_rules.mdc を利用します。
これらは AI アシスタントとのインタラクティブな対話を通じて自動更新が行われます。

> [!WARNING]
>
> windsurf
> - global: global_rules.md
> - local: .windsurfrules
> - docs: https://docs.codeium.com/windsurf/memories#windsurfrules
>
> cursor
> - global: global_rules.mdc
> - local: project_rules.mdc
> - docs: https://docs.cursor.com/context/rules-for-ai
>

## ✨ 主な機能

- 🔄 **インタラクティブセットアップ**: .windsurfrules / project_rules.mdc をインタラクティブにチューニング
- 📝 **高品質な共通設定ファイル**: 事前定義された高品質な global_rules.md / global_rules.mdc
- ⚡ **タスク指向のショートカット**: 各タスクで汎用的に利用可能なショートカット

## 🚀 クイックスタート

1. リポジトリをクローン:
```bash
git clone https://github.com/hashiiiii/rules-for-ai.git
```

2. 任意のワークスペースを IDE で開きルールファイルを設定:
   - `.windsurfrules` / `global_rules.md` - Windsurf IDE 用
   - `project_rules.mdc` / `global_rules.mdc` - Cursor IDE 用

> [!IMPORTANT]
>
> グローバル設定のみで十分な場合は移行の手順は不要です。
>

3. セットアップコマンドの実行
   - `/setup` コマンドを実行

4. 保存コマンドの実行
   - `/store` コマンドを実行

## 🔍 利用可能なショートカット

- `/setup`   : セットアッププロセスを開始します
- `/adjust`  : 現在のワークスペース設定ファイルを微調整します
- `/store`   : セットアッププロセスによって得られた回答をもとにファイルを更新します
- `/plan`    : 詳細な作業計画の作成
- `/debug`   : 体系的なデバッグアプローチ
- `/review`  : コード品質レビュー
- `/refactor`: 可読性と保守性の向上
- `/optimize`: パフォーマンス最適化の提案
- `/test`    : テスト戦略
- `/doc`     : ドキュメント作成の支援
- `/arch`    : アーキテクチャ設計
- `/cmt`     : コードコメント
- `/mvp`     : MVP (Minimum Viable Product) を構築
- `/help`    : 利用可能なショートカットを表示

## 📄 ライセンス

このプロジェクトはMITライセンスの下で提供されています - 詳細は[LICENSE.md](LICENSE.md)ファイルをご覧ください。
