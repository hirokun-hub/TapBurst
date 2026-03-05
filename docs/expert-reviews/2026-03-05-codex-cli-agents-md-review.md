# Codex CLI AGENTS.md ベストプラクティス -- 専門家レビュー

> レビュー日: 2026-03-05
> レビュー対象: TapBurst リポジトリ用 AGENTS.md の設計方針
> 回答者: 3名の専門家（O, A, G）
> Codex CLI バージョン: codex-cli 0.107.0

---

## 1. AGENTS.md の読み込み仕様（全専門家一致、信頼度95%以上）

### 読み込みパスと優先順位

Codex CLI はセッション開始時に以下の順でファイルを探索し、連結してインストラクションチェーンを構築する:

1. **グローバル (`~/.codex/`)**: `AGENTS.override.md` があればそれ、なければ `AGENTS.md`（1ファイルのみ）
2. **プロジェクト階層**: Git ルートから CWD まで下に向かって各ディレクトリを走査。各ディレクトリで `AGENTS.override.md` → `AGENTS.md` → `project_doc_fallback_filenames` の順に確認（1ディレクトリにつき最大1ファイル）
3. **マージ順序**: ルートから CWD に向かって連結。より深い（CWDに近い）ファイルの指示が優先される

ソース: https://developers.openai.com/codex/guides/agents-md/

### サイズ制限

- デフォルト上限: **`project_doc_max_bytes = 32768`（32 KiB）**
- 全ディレクトリの AGENTS.md を連結した合計がこの上限に達した時点で読み込みを打ち切る
- 上限超過時は **警告なしにサイレントトランケート** される（GitHub Issue として報告済み）
- `config.toml` で変更可能（最大 65536 等に引き上げ可能）

ソース: https://developers.openai.com/codex/config-advanced/

### @import 機構

**存在しない。** Claude Code の `@path/to/file` 構文に相当する機能は Codex CLI の AGENTS.md には実装されていない（全専門家一致）。代替手段:
- サブディレクトリ分割（ディレクトリ階層での積み上げ）
- `project_doc_fallback_filenames` で追加ファイル名を登録

### instructions.md との関係

`instructions.md` は Codex CLI のデフォルト自動読み込み対象ではない（全専門家一致）。使用したい場合は `config.toml` の `project_doc_fallback_filenames` にパスを追加する必要がある。**AGENTS.md に統一すべき。**

### サブディレクトリ AGENTS.md の読み込みタイミング

**起動時に CWD までのパス上のみ読み込み。** Claude Code の「サブツリーのファイルを読んだとき自動インクルード」とは異なり、CWD より深いサブディレクトリの AGENTS.md は起動時に読み込まれない。`codex --cd path/to/subdir` で明示的に CWD を変更して起動する必要がある。

---

## 2. CLAUDE.md → AGENTS.md 変換の注意点（全専門家ほぼ一致）

### Claude Code と Codex CLI の前提差異

| 項目 | Claude Code | Codex CLI |
|---|---|---|
| サンドボックス | なし（OS 直接） | あり（macOS Seatbelt / Linux Landlock） |
| ネットワーク | 制限なし | **デフォルトでブロック** |
| ファイル読み込みツール | あり（Read ツール） | あり（shell ツール経由） |
| @import 構文 | あり | **なし** |
| 指示ファイルサイズ上限 | なし（実質的制限のみ） | **32 KiB** |
| 自動 compaction | あり | あり |

### チェックリスト形式の有効性

- 専門家間で信頼度にばらつきあり（60%〜95%）
- `- [ ]` 形式自体は機能するが、Codex CLI の UI でチェックボックスとして扱われるわけではない
- 32 KiB 制限で末尾が切り捨てられるリスクがあるため、**重要な制約は前半に配置**すべき（専門家O指摘）

### Codex CLI 特有の推奨セクション

- **ビルド・テストコマンド**: Codex は自律的にコマンドを実行する傾向があるため、正確なコマンドを明記（全専門家一致）
- **サンドボックス注記**: ネットワークがデフォルトブロックである旨を記載（専門家A, O）
- **承認ポリシー**: 実行前確認の方針を明示（専門家O）

---

## 3. 64KB 設計書の参照戦略（全専門家一致）

- AGENTS.md に設計書の全文を含めるのは**不可能**（32 KiB 制限の2倍）
- **パス記載 + 重要制約の要約** が最適（Claude Code と同じ戦略）
- Codex はファイル読み込みツールを持つため、パスを明示しておけば必要時に自分で読みに行く

---

## 4. CLAUDE.md / AGENTS.md の同期戦略（全専門家ほぼ一致）

### シンボリックリンク方式

全専門家が推奨。1つのファイルを更新するだけで両エージェントに同じコンテキストを共有:

```bash
# CLAUDE.md を正本とし、AGENTS.md をシンボリックリンクにする
ln -s CLAUDE.md AGENTS.md
```

### project_doc_fallback_filenames 方式（専門家A, O推奨）

`~/.codex/config.toml` または `.codex/config.toml` に以下を追加:

```toml
project_doc_fallback_filenames = ["CLAUDE.md"]
```

これにより AGENTS.md が存在しない場合に Codex が CLAUDE.md を読み込む。

### グローバル vs リポジトリの責務分離

Claude Code と同一基準（全専門家一致）:
- グローバル `~/.codex/AGENTS.md`: 全プロジェクト共通ルール
- リポジトリ `./AGENTS.md`: プロジェクト固有ルール
- Swift/iOS 共通ルールはリポジトリ側に置くべき（グローバルに置くとノイズになる）

---

## 5. Codex CLI 固有の機能

### Skills（SKILL.md）

Codex CLI には Skills 機能があり、必要時だけ本文をロードできる。設計書の参照方法を Skill 化することで、コンテキスト効率を高められる（専門家O指摘）。

### AGENTS.override.md

特定のディレクトリだけルールを差し替える場合に使用。AGENTS.md より優先される。

---

## 情報ソース

| ソース | URL |
|---|---|
| 公式 AGENTS.md ガイド | https://developers.openai.com/codex/guides/agents-md/ |
| 公式 Config リファレンス | https://developers.openai.com/codex/config-advanced/ |
| OpenAI Codex 紹介記事 | https://openai.com/index/introducing-codex/ |
| AGENTS.md 仕様 Deep Dive | https://gist.github.com/0xdevalias/f40bc5a6f84c4c5ad862e314894b2fa6 |
| 並行運用事例 (concret.io) | https://www.concret.io/blog/sync-coding-standards-across-cursor-agentforce-vibes-claude |

---

## 変更履歴

| 日付 | 変更内容 |
|---|---|
| 2026-03-05 | 初版作成。3名の専門家レビュー結果を統合 |
