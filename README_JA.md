# 🤖 Rules for AI

ドキュメント ([English](https://github.com/hashiiiii/rules-for-ai/blob/main/README.md), [日本語](https://github.com/hashiiiii/rules-for-ai/blob/main/README_JA.md))

## 📋 概要

開発者向け AI アシスタントとの対話を強化するためのルールとガイドラインのコレクションです。Windsurf、Cursorなどのコーディング支援 AI 向けに設計されています。グローバル設定には事前定義された windsurf: global_rules.md / cursor: .cursorrules を利用し、各ワークスペース毎の独自のチューニングを windsurf: .windsurfrules / cursor: project_rules.mdc に設定します。これらは AI アシスタントとのインタラクティブな対話を通じて自動更新されます。

> [!WARNING]
>
> windsurf
> - global: global_rules.md
> - local: .windsurfrules
> - docs: https://docs.codeium.com/windsurf/memories#windsurfrules
>
> cursor
> - global: .cursorrules
> - local: project_rules.mdc
> - docs: https://docs.cursor.com/context/rules-for-ai
>

## ✨ 主な機能

- 🔄 **インタラクティブセットアップ**: .windsurfrules / project_rules.mdc をインタラクティブにチューニング
- 📝 **高品質な共通設定ファイル**: 事前定義された高品質な global_rules.md / .cursorrules
- ⚡ **タスク指向のショートカット**: 一般的な開発タスク用の事前定義されたエイリアス

## 🚀 クイックスタート

1. リポジトリをクローン:
```bash
git clone https://github.com/hashiiiii/rules-for-ai.git
```

2. 任意のワークスペースを IDE で開きルールファイルを設定:
   - `.windsurfrules` / `global_rules.md` - Windsurf IDE 用
   - `project_rules.mdc` / `.cursorrules` - Cursor IDE 用
   
3. セットアップコマンドの実行
   - ※ global_rules.md / .cursorrules で十分な場合は以降の手順は不要
   - `/setup` コマンドを write モードで実行

4. .windsurfrules / project_rules.mdc が更新されたことを確認する
   - 更新が行われない場合は、write モードで AI アシスタントに更新を依頼してください

## ⚙️ .windsurfrules / project_rules.mdc

`.windsurfrules` / `project_rules.mdc` ファイルは、AIアシスタントの動作をあなたの特定のニーズに合わせてカスタマイズするためのインタラクティブなセットアッププロセスを提供します。

## 🔧 カスタマイズ

`/setup`初期セットアップ完了後、さらに設定を調整することができます。
`/adjust`を使用して現在の構成を微調整できます。

## 🔍 利用可能なショートカット

以下のショートカットが利用可能です:

- `/setup`   : セットアッププロセスを開始します
- `/adjust`  : 現在の構成を微調整します
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
