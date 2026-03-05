# TapBurst

iPhone向けランドスケープ専用タップ連打ゲーム。10秒間のタップ数を競い、CPS/時間軸の2軸エスカレーションで演出が変化する。

## 開発者コンテキスト

- 開発者はiOS/Swift未経験。基本的な概念も丁寧に説明すること
- ビルド環境: Xcode (macOS), 実機テスト用iPhone あり
- 日本語でコミュニケーション

## 技術スタック

- Swift 5 / iOS 17.0+
- SwiftUI（画面構成・HUD・背景エフェクト） + UIKit（タッチ検出: UIViewRepresentable）
- AVAudioEngine（低レイテンシ音声再生、64-sample buffer @44.1kHz）
- Core Animation / CAEmitterLayer（タップ位置パーティクル、GPU描画）
- iPhone専用（iPhone SE 3rd gen 〜 iPhone 16 Pro Max）

## ドキュメント正本

IMPORTANT: 要件定義・設計書は v1.5 が正本。`docs/requirements.md`（v1.0）は旧版であり参照禁止。

| ドキュメント | パス | 用途 |
|---|---|---|
| 要件定義書 v1.5 | `.kiro/specs/tapburst-game/requirements.md` | 機能要件・非機能要件の正本 |
| 設計書 | `.kiro/specs/tapburst-game/design.md` | アーキテクチャ・実装仕様の正本 |
| タスクリスト | `.kiro/specs/tapburst-game/tasks.md` | 実装進捗管理 |
| 専門家レビュー | `docs/expert-reviews/` | 技術レビュー記録（参考資料） |

設計書は約64KBあるため @import せず、必要なセクションを都度 Read すること。

## 技術的制約チェックリスト

実装時に以下を自己チェックすること（詳細は設計書の該当セクション参照）:

- [ ] 定数をグローバル Constants.swift に集約していないか（→ 使用する型の内部に定義: 設計書§0）
- [ ] 画面はランドスケープ専用か（ポートレート不可: 設計書§13, NFR-4）
- [ ] タッチ検出は UIViewRepresentable + touchesBegan/Moved/Ended を使用しているか（設計書§7）
- [ ] パーティクルは CAEmitterLayer で実装しているか（SpriteKit不使用: 設計書§9.1）
- [ ] 音声再生は AVAudioEngine を使用しているか（AVAudioPlayer不使用: 設計書§8）
- [ ] GameManager は @Observable マクロを使用しているか（ObservableObject不使用: 設計書§4）
- [ ] HUD（スコア・タイマー）は allowsHitTesting(false) か（設計書§6）
- [ ] エスカレーションは TimeStage と CPSTier の2軸で制御しているか（設計書§5）
- [ ] スコアカードは ImageRenderer 専用View で生成しているか（設計書§10）
- [ ] シェアは UIActivityViewController 経由か（設計書§10）
- [ ] UserDefaults のキーは ScoreStore 内に閉じているか（設計書§11）
- [ ] ローカライゼーションは String Catalog (.xcstrings) を使用しているか（設計書§12）
- [ ] iPhone SE 3rd gen のパフォーマンス予算内か（設計書§9, NFR-10）

## 設計原則

- 定数は使用する型の内部に `static let` / `static var` で定義する（グローバル定数ファイル禁止）
- 設計書の内容を CLAUDE.md やコードコメントに転記しない（二重管理禁止）
- TDD対象タスク（tasks.md で `TDD` マーク付き）はテストを先に書く
- コミットメッセージに対応タスク番号を含める（例: `T-010: ScoreRecord モデル実装`）
- 要件ID (REQ-xx, NFR-xx) の変更は要件定義書を先に更新し、設計書との整合性を確認してから実装する

## ビルド・テストコマンド

```bash
# ビルド
xcodebuild -project TapBurst.xcodeproj -scheme TapBurst -destination 'platform=iOS Simulator,name=iPhone 16' build

# 全テスト実行
xcodebuild -project TapBurst.xcodeproj -scheme TapBurst -destination 'platform=iOS Simulator,name=iPhone 16' test

# 単一テストファイル実行
xcodebuild -project TapBurst.xcodeproj -scheme TapBurst -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:TapBurstTests/ScoreStoreTests
```

## 進捗

現在の実装進捗は `.kiro/specs/tapburst-game/tasks.md` を参照。
