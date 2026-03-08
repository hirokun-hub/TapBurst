# TapBurst MVP 実装タスクリスト / Implementation Task List

> 対応設計書 / Design: [design.md](./design.md) v1.7
> 対応要件定義書 / Requirements: [requirements.md](./requirements.md) v1.7

---

## 凡例 / Legend

- `[x]` 完了 / Done
- `[ ]` 未着手 / Not started
- `[~]` 作業中 / In progress
- `🧪 TDD` テスト駆動開発対象（テストを先に書く）/ Test-driven development target (write tests first)
- `📐 Xcode GUI` Xcode GUIでの操作が必要 / Requires Xcode GUI operation
- `🔊 Asset` サウンド・画像等のアセット準備 / Sound/image asset preparation

---

## Phase 0: プロジェクト設定 / Project Setup

> design.md §13 対応

- [x] **T-001** Xcodeプロジェクト設定変更
  - `project.pbxproj` 直接編集で実施（Xcode GUI不要）
  - `TARGETED_DEVICE_FAMILY` → `1` (iPhone only) — 全ターゲット（TapBurst, Tests, UITests）
  - `IPHONEOS_DEPLOYMENT_TARGET` → `17.0` — プロジェクトレベル＋全ターゲット
  - `UISupportedInterfaceOrientations_iPhone` → Landscape Left + Landscape Right のみ（Portrait削除）
  - `UISupportedInterfaceOrientations_iPad` → 削除（iPhone専用のため不要）
  - `UIRequiresFullScreen` → `YES`（Debug/Release両方）
  - `SWIFT_VERSION` → `5.0`（変更なし、確認済み）
  - 対応要件: NFR-4, NFR-9
- [x] **T-002** ローカライゼーション設定
  - `project.pbxproj` 直接編集で実施（Xcode GUI不要）
  - `knownRegions` に `ja` を追加
  - `TapBurst/Localizable.xcstrings` (String Catalog) を空テンプレートとして作成
  - 対応要件: NFR-5
- [x] **T-003** フォルダ構成の作成
  - `TapBurst/Models/`, `ViewModels/`, `Views/`, `Views/Components/`, `UIKit/`, `Services/`, `Resources/Sounds/` を作成
  - `PBXFileSystemSynchronizedRootGroup` により Xcode が自動認識することを確認
  - 注意: `.gitkeep` は `PBXFileSystemSynchronizedRootGroup` と競合しビルドエラーとなるため使用不可。空ディレクトリはgitで追跡されないが、Phase 1以降でSwiftファイル追加時に自動的に追跡対象となる
  - 対応設計: §1
- [x] **T-004** Launch Screen を設定
  - `UILaunchScreen_Generation = YES`（自動生成）を維持 — App Store審査ガイドラインに準拠
  - `UIStatusBarStyle = UIStatusBarStyleDefault` を追加（Debug/Release両方）
  - 背景色・アプリ名等のカスタマイズはビジュアルデザイン確定後（Phase 5以降）に実施予定
  - 対応要件: NFR-17

---

## Phase 1: データモデル / Data Models 🧪 TDD

> design.md §3 対応。全て純粋ロジックのため TDD で実装する。
> テストファイル: `TapBurstTests/ModelsTests.swift`

- [x] **T-010** `🧪 TDD` `GamePhase.swift` を実装
  - enum: `.home`, `.countdown`, `.playing`, `.results`
  - テスト: 4つのcaseが存在することの確認
  - 対応要件: —（基盤型）
- [x] **T-011** `🧪 TDD` `TitleDefinition.swift` を実装
  - `key` プロパティ（ローカライゼーションキー文字列）+ `localizedNameKey` は `key` から導出
  - `allTitles` 配列（10段階の称号テーブル）
  - `title(for:)` スコア→称号マッピング
  - `localizedName` プロパティ
  - テスト: 全20境界値で `key` が期待キーと一致することを検証
  - テスト: 全スコア範囲がギャップなくカバーされていること
  - 対応要件: REQ-17, Appendix A
- [x] **T-012** `🧪 TDD` `TimeStage.swift` を実装
  - enum: `.calm`, `.warm`, `.intense`
  - `stage(at:)` 経過時間→段階マッピング
  - 閾値: `warmThreshold = 5.0`, `intenseThreshold = 8.0`（型内部に定義）
  - テスト: 境界値テスト（0, 4.99→calm, 5.0→warm, 7.99→warm, 8.0→intense, 10.0→intense）
  - 対応要件: REQ-12, Appendix B
- [x] **T-013** `🧪 TDD` `CPSTier.swift` を実装
  - enum: `.t0`〜`.t7`（8段階）（V3-020 で3段階→8段階に拡張）
  - `tier(for:)` CPS→段階マッピング（閾値: 5/8/11/15/19/23/27）
  - `baseHSB` プロパティ: 成分別べき指数カーブ（紺→紫→マゼンタ→橙赤）（V3-EscCurve で対数的前倒しに最適化）
  - テスト: 16境界値パターン + baseHSB t0/t7 値検証
  - 対応要件: REQ-15, Appendix B
- [x] **T-014** `🧪 TDD` `ParticleConfig.swift` を実装
  - `birthRate`, `scale`, `lifetime`, `velocity`, `color` プロパティ
  - `.t0`〜`.t7` static定数（V3-040 で8段階化）
  - `config(for:)` CPSTier→ParticleConfig マッピング
  - テスト: 各tierの値が設計書の値と一致すること（8段階）
  - 対応要件: REQ-10, REQ-15
- [x] **T-015** `🧪 TDD` `PitchConfig.swift` を実装
  - `pitchShift` プロパティ（cent単位）
  - 8段階テーブル: 0/150/280/400/520/630/700/750（V3-EscCurve で750cent上限・減速型に最適化）
  - `config(for:)` CPSTier→PitchConfig マッピング（離散値）
  - `interpolatedPitchShift(for cps:)` CPS値からtier境界間を線形補間（連続的ピッチ変化）
  - AudioService は `interpolatedPitchShift` を使用し、CPS値に応じた滑らかなピッチ遷移を実現
  - テスト: 各tierの値が設計書の値と一致すること（8段階）+ 補間キーポイント一致・中間値・境界クランプ
  - 対応要件: REQ-13, REQ-15
- [x] **T-016** `GameSession.swift` を実装
  - `score`, `maxSimultaneousTouches`, `tapTimestamps`, `startTime` プロパティ
  - 対応要件: REQ-5, REQ-6
- [x] **T-017** `ScoreResult.swift` を実装
  - `score`, `cps`, `maxSimultaneousTouches`, `title`, `isNewBest`, `playedAt` プロパティ
  - 対応要件: REQ-16

---

## Phase 2: サービス層 / Services

> design.md §8, §11 対応

- [x] **T-020** `🧪 TDD` `ScoreStore.swift` を実装
  - `bestScore` computed property（UserDefaults wrapper）
  - `updateIfNeeded(score:) -> Bool`
  - `todayBestScore` computed property（保存日付が今日でなければ0を返す）
  - `updateTodayIfNeeded(score:) -> Bool`
  - `resetAll()` — bestScore, todayBestScore, todayBestDate の3キーを削除
  - `dateProvider: () -> Date` init引数（テスト時の日付制御用）
  - テスト: 高スコア時にtrue + 更新、低スコア時にfalse + 据え置き、初期値0
  - テスト: todayBestScore初期値0、高スコア更新、低スコア不更新、日付跨ぎリセット
  - テスト: resetAll後に両スコア0、resetAll後の再更新可能
  - 対応要件: REQ-20, REQ-22, NFR-11, NFR-12
- [x] **T-021** `HapticsService.swift` を実装
  - `UIImpactFeedbackGenerator(style: .light)`
  - `triggerTapFeedback()` 60fps間引き（`minimumInterval = 0.016`）
  - 対応要件: REQ-11
- [x] **T-022** `AudioService.swift` を実装
  - AVAudioEngine セットアップ
  - AVAudioSession category `.ambient`
  - バッファサイズ 64サンプル設定
  - バッファ読込を先行し、バッファの `format` を使って `engine.connect()` に明示指定（チャンネル数ミスマッチ防止）
  - `isEngineReady` ガードで音声リソース不在時のクラッシュ防止
  - AVAudioPlayerNode ×4 プール + AVAudioUnitTimePitch
  - `playTapSound(tier:)` ラウンドロビン + ピッチ制御
  - `playCountdownTick(number:)` 各秒固有音再生（3/2/1）
  - `playGo()`, `playFinish()`
  - 対応要件: REQ-13, REQ-14, REQ-15, NFR-15
- [x] **T-023** `🔊 Asset` サウンドアセットの準備
  - `tap.caf`, `countdown3.caf`, `countdown2.caf`, `countdown1.caf`, `go.caf`, `finish.caf`
  - `.caf` 形式（デコードオーバーヘッドゼロ）
  - `Resources/Sounds/` に配置
  - 対応要件: REQ-13, REQ-14

---

## Phase 3: UIKit タッチ検出層 / UIKit Touch Detection Layer

> design.md §7 対応

- [x] **T-030** `GameTouchView.swift` (UIViewRepresentable) を実装
  - `TouchDetectionView` (UIView subclass)
  - `isMultipleTouchEnabled = true`
  - `touchesBegan` → `onTaps(count, positions)` クロージャ通知
  - 対応要件: REQ-6, REQ-7, NFR-2
- [x] **T-031** `TouchDetectionView` にパーティクル生成を実装
  - `spawnParticleEmitter(at:)` — CAEmitterLayer + CAEmitterCell
  - birthRate設定 → `emitterStopDelay`(0.05s)後停止 → `emitterRemoveDelay`(0.5s)後remove
  - ParticleConfig による段階別パラメータ適用
  - renderMode `.additive`, テクスチャ 16-32pt
  - 対応要件: REQ-10

---

## Phase 4: GameManager（中央状態管理）/ Central State Manager

> design.md §4, §5 対応

- [x] **T-040** `GameManager.swift` 基本構造を実装
  - `@MainActor @Observable class`
  - 全プロパティ定義（phase, session, result, remainingTime, currentCPS, etc.）
  - 全定数定義（gameDuration, countdownStart, shakeAmplitude, flashInterval, invalidShakeAmplitude）
  - サービス依存（ScoreStore, AudioService, HapticsService）
  - `bestScore` / `todayBestScore` 初期ロード
  - `resetScores()` — scoreStore.resetAll() + 表示用プロパティリセット
  - `handleForeground()` — ホーム画面状態で todayBestScore を再取得（日付跨ぎ対応）
  - 対応要件: —（基盤）
- [x] **T-041** カウントダウンロジックを実装
  - `startGame()` — phase → .countdown, `UIApplication.shared.isIdleTimerDisabled = true`, Timer.scheduledTimer(1秒間隔, クロージャ+[weak self])
  - `countdownNumber`: 3→2→1→nil(GO!)
  - `playCountdownTick(number:)` 各秒固有音
  - `beginPlaying()` — CADisplayLink 開始
  - 対応要件: REQ-1, REQ-2, REQ-14, NFR-7
- [x] **T-042** カウントダウン中の誤タップ処理を実装
  - `registerInvalidCountdownTap()` — スコア不変（REQ-3）
  - 軽い画面振動（±2pt, Spring 0.3s）
  - `invalidTapOverlayOpacity` + フェードアウト
  - 対応要件: REQ-3, REQ-4
- [x] **T-043** ゲームループ（displayLinkFired）を実装
  - `elapsed = CACurrentMediaTime() - startTime`
  - `remainingTime = max(0, gameDuration - elapsed)`
  - CPS算出: tapTimestamps から1秒以上古い要素を除去、残要素数 = currentCPS
  - TimeStage / CPSTier 評価
  - `elapsed >= gameDuration` で `endGame()` 呼び出し
  - 対応要件: REQ-5, REQ-9, NFR-1, NFR-3
- [x] **T-044** タップ登録ロジックを実装
  - `registerTaps(count:, positions:)` — phase == .playing 限定
  - `score += count`, `tapTimestamps.append`, `maxSimultaneousTouches` 更新
  - AudioService.playTapSound(tier:) + HapticsService.triggerTapFeedback() 呼び出し
  - 対応要件: REQ-6, REQ-7, REQ-8, REQ-11, REQ-13
- [x] **T-045** 演出状態更新を実装
  - `.intense` 時: shakeOffset ±shakeAmplitude / flashOpacity 0.7秒間隔
  - `.warm` 時: shakeOffset = .zero
  - 毎フレーム displayLinkFired 内で実行
  - 対応要件: REQ-12
- [x] **T-046** ゲーム終了・結果生成を実装
  - `endGame()` — CADisplayLink停止, isIdleTimerDisabled = false
  - `ScoreResult` 生成（score, cps, maxSimultaneousTouches, title, isNewBest, playedAt）
  - `ScoreStore.updateIfNeeded(score:)` + `updateTodayIfNeeded(score:)` 呼び出し
  - `bestScore` / `todayBestScore` 再取得
  - `phase = .results`
  - `audioService.playFinish()`
  - 対応要件: REQ-9, REQ-16, REQ-17, REQ-20, REQ-22
- [x] **T-047** リトライ・ホーム遷移を実装
  - `retry()` — スコアリセット → `startGame()` 呼び出し
  - `goHome()` — `phase = .home`, `todayBestScore` 再取得（日付跨ぎ対応）
  - 対応要件: REQ-18, REQ-19
- [x] **T-048** バックグラウンド移行処理を実装
  - `handleBackground()` — `.countdown`/`.playing` フェーズのみ実行（guard）、セッション破棄, CADisplayLink停止, Timer停止, phase = .home
  - `isIdleTimerDisabled = false`
  - 対応要件: REQ-26

---

## Phase 5: SwiftUI Views / 画面実装

> design.md §2, §6, §10, §12 対応

### 5a: コンポーネント / Components

- [x] **T-050** `BackgroundEffectView.swift` を実装
  - `LinearGradient` — CPSTier 単独制御（baseHSB 8段階: 紺→紫→マゼンタ→橙赤）（V3-060 で改定）
  - `.id(cpsTier).transition(.opacity)` クロスフェード方式（色相補間回避）
  - `RadialGradient` ビネットオーバーレイ（TimeStage制御: calm=0, warm=0.3, intense=0.5）
  - `animation(.easeInOut)` でTimeStage遷移
  - 対応要件: REQ-12
- [x] **T-051** `FlashOverlayView.swift` を実装
  - `Color.white.opacity(opacity)` — flashOpacity に連動
  - `allowsHitTesting(false)`
  - 対応要件: REQ-12
- [x] **T-052** `GameHUDView.swift` を実装
  - ZStackレイアウト: スコアを画面中央、タイマーを右上に配置（REQ-8「画面中央」準拠）
  - スコア表示: 80pt固定フォントサイズ（≥72pt, Dynamic Type無視）
  - 残り時間表示: 数値のみ（ラベルなし）、右上配置
  - `allowsHitTesting(false)`
  - 対応要件: REQ-8, NFR-8, NFR-14
- [x] **T-053** `ScorecardView.swift` を実装
  - ImageRenderer専用View（390×600pt）
  - `Image("ScorecardLogo")` — 専用ロゴアセット
  - スコア, 称号, CPS, プレイ日時（`.dateTime` format — date+time）
  - App Store誘導要素（v1: アプリ名テキスト）
  - `generateScorecardImage()` 関数（@MainActor）
  - 対応要件: REQ-23, REQ-24, REQ-25

### 5b: 画面 / Screens

- [x] **T-060** `HomeView.swift` を実装
  - 2カラム HStack レイアウト（左: タイトル+スコアパネル、右: STARTボタン）
  - タイトル: 白テキスト + オレンジグロー shadow
  - スコアパネル: 歴代ベスト（+称号名）、今日のベスト、差分テキスト（条件付き）
  - 未プレイ時は「---」表示
  - リセットボタン（パネル外下部）→ confirmationDialog → `gameManager.resetScores()`
  - STARTボタン: `.phaseAnimator` パルスアニメーション（1.0↔1.04）
  - VoiceOverアクセシビリティ（labels, values, hints, traits, reading order）
  - 対応要件: REQ-1, REQ-21, NFR-13
- [x] **T-061** `CountdownView.swift` を実装
  - カウントダウン数字表示（3, 2, 1, GO!）
  - 全面タップ検出（`contentShape(Rectangle())` + `onTapGesture`）
  - 誤タップ時の半透明オーバーレイ + 「まだだよ!/Not yet!」
  - `.offset(shakeOffset)` で振動適用
  - 対応要件: REQ-1, REQ-3, REQ-4
- [x] **T-062** `GamePlayView.swift` を実装
  - ZStack 4層レイヤー構成:
    1. BackgroundEffectView（allowsHitTesting false）
    2. GameTouchView（タッチ受付）
    3. FlashOverlayView（allowsHitTesting false）
    4. GameHUDView（allowsHitTesting false）
  - `.offset(shakeOffset)` 全体振動
  - ステータスバー非表示（`prefersStatusBarHidden`）
  - 対応要件: REQ-8, REQ-10, REQ-12, NFR-6, NFR-7, NFR-8
- [x] **T-063** `ResultsView.swift` を実装
  - スコア, CPS, 最大同時タッチ数, 称号 表示
  - NEW BEST! 表示（`isNewBest` 時）
  - 「もう1回」ボタン → `gameManager.retry()`
  - 「シェア」ボタン → スコアカード画像生成 → UIActivityViewController
  - 「ホームに戻る」ボタン → `gameManager.goHome()`
  - VoiceOverアクセシビリティ（labels, values, hints, traits, reading order）
  - 対応要件: REQ-16, REQ-17, REQ-18, REQ-19, REQ-22, REQ-23, NFR-13

---

## Phase 6: アプリエントリポイント / App Entry Point

> design.md §2, §4 対応

- [x] **T-070** `ContentView.swift` を修正
  - `GameManager` を `let` で受け取り（所有権は `TapBurstApp` の `@State`）
  - `gameManager.phase` による switch 分岐:
    - `.home` → HomeView
    - `.countdown` → CountdownView
    - `.playing` → GamePlayView
    - `.results` → ResultsView
  - 対応要件: —（基盤）
- [x] **T-071** `TapBurstApp.swift` を修正
  - `@Environment(\.scenePhase)` 監視
  - `.background` 検知 → `gameManager.handleBackground()`
  - `.active` 検知 → `gameManager.handleForeground()`（日付跨ぎ時の todayBestScore 再取得）
  - 対応要件: REQ-26

---

## Phase 7: ローカライゼーション / Localization

> design.md §12 対応

- [x] **T-080** `Localizable.xcstrings` に全キーを登録
  - UI文言キー: `home.start`, `home.best_score`, `home.today_best`, `home.until_new_best %lld`, `home.reset_confirmation_title`, `home.reset_all`, `countdown.ready`, `game.tap_invalid`, `results.score`, `results.cps`, `results.max_touches`, `results.new_best`, `results.retry`, `results.share`, `results.go_home`
  - 称号キー: `title.first_steps` 〜 `title.god_tier`（10件）
  - A11yキー: `a11y.home.start_hint`, `a11y.home.reset_label`, `a11y.home.reset_hint`, `a11y.results.title_label`, `a11y.results.retry_hint`, `a11y.results.share_hint`, `a11y.results.home_hint`
  - 日本語・英語の2言語分
  - 対応要件: NFR-5

---

## Phase 8: アセット / Assets

> design.md §10, §13 対応

- [ ] **T-090** `🔊 Asset` `ScorecardLogo` 画像を `Assets.xcassets` に追加
  - スコアカード専用ロゴ（AppIconとは別管理）
  - 対応要件: REQ-25
- [ ] **T-091** `🔊 Asset` アプリアイコン（1024×1024）を `Assets.xcassets` に追加
  - AppIcon イメージセット
  - 対応要件: NFR-16

---

## Phase 9: 統合テスト・検証 / Integration & Verification

- [ ] **T-100** E2E-1: 初回起動 → START → カウントダウン → 10秒タップ → 結果画面に4指標が表示される
- [ ] **T-101** E2E-2: 自己ベスト更新 → 「NEW BEST!」表示 → ホーム画面で更新確認
- [ ] **T-102** E2E-3: 結果画面「もう1回」→ カウントダウンから再開
- [ ] **T-103** E2E-4: 「シェア」→ スコアカード画像生成 → シェアシート → 外部アプリ送信
  - スコアカード画像の完了基準:
    - Portrait比率（390×600pt）
    - ScorecardLogo 画像が表示されている
    - スコア、CPS、称号が正しく含まれている
    - プレイ日時（date + time）が表示されている
    - App Store誘導要素（v1: アプリ名テキスト）が含まれている
  - 対応要件: REQ-23, REQ-24, REQ-25
- [ ] **T-104** E2E-5: 5本指同時タップで5カウント加算
- [ ] **T-105** E2E-6: アプリタスクキル → 再起動 → 自己ベスト復元
- [ ] **T-106** E2E-7: カウントダウン中タップ → 視覚フィードバック + スコア不変
- [ ] **T-107** E2E-8: ゲーム中バックグラウンド → 復帰 → ホーム画面
- [ ] **T-108** NFR検証: 横向き固定、ステータスバー非表示、スリープ無効化、サイレントモード対応
- [ ] **T-109** NFR検証: VoiceOver動作確認（ホーム画面・結果画面）
- [ ] **T-110** NFR検証: iPhone SE 3rd + iPhone 16 Pro Max でのUI/パフォーマンス確認
  - iPhone SE 3rd: 60fps維持、最小画面でのレイアウト崩れなし（NFR-10, NFR-3）
  - iPhone 16 Pro Max: Landscape でのUI要素クリッピング・重なりなし、タップエリア全画面有効（NFR-10）
- [ ] **T-111** NFR検証: 日本語/英語切替で全文言が正しく表示される
- [ ] **T-112** NFR検証: Launch Screen が正しく表示される（起動時に白画面・黒画面にならない）
  - 対応要件: NFR-17

---

## 依存関係 / Dependencies

```
Phase 0 (T-001〜T-004) ─── 先行必須 ───→ 全Phase
Phase 1 (T-010〜T-017) ─── 先行必須 ───→ Phase 2, 3, 4, 5
Phase 2 (T-020〜T-023) ─── 先行必須 ───→ Phase 4
Phase 3 (T-030〜T-031) ─── 先行必須 ───→ Phase 4
Phase 4 (T-040〜T-048) ─── 先行必須 ───→ Phase 5, 6
Phase 5 (T-050〜T-063) ─── 先行必須 ───→ Phase 6
Phase 6 (T-070〜T-071) ─── 先行必須 ───→ Phase 9
Phase 7 (T-080)        ─── 並行可能 ───→ Phase 5以降で段階的に適用可
Phase 8 (T-090〜T-091) ─── 並行可能 ───→ Phase 5以降で段階的に適用可
Phase 9 (T-100〜T-112) ─── 最後 ───→ 全Phase完了後
```

---

## TDD対象まとめ / TDD Targets Summary

| タスク | ファイル | テスト観点 |
|--------|---------|-----------|
| T-010 | GamePhase.swift | 4つのcaseが存在することの確認 |
| T-011 | TitleDefinition.swift | 10段階の境界値（20パターン）+ キー一致検証 + ギャップなしカバー |
| T-012 | TimeStage.swift | 3段階の境界値（6パターン） |
| T-013 | CPSTier.swift | 8段階の境界値（16パターン）+ baseHSB t0/t7 値検証 |
| T-014 | ParticleConfig.swift | 8段階のパラメータ正確性 |
| T-015 | PitchConfig.swift | 8段階のピッチ値正確性（750cent上限・減速型）+ 連続補間（キーポイント一致・中間値・クランプ） |
| T-020 | ScoreStore.swift | 高スコア更新・低スコア据え置き・初期値・todayBest初期値/更新/不更新/日付跨ぎ・resetAll |
| V3-060 | CPSTier.swift, CPSTierFilter.swift | baseHSB t0/t7 値検証 + ヒステリシス 6件（上昇/下降/pending解除/tier変更リセット/reset） |

テストファイル構成:
- `TapBurstTests/ModelsTests.swift` — T-010〜T-015, V3-060
- `TapBurstTests/ScoreStoreTests.swift` — T-020
