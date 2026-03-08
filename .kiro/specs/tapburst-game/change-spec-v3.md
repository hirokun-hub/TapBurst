# TapBurst v3 変更仕様書

> 対応設計書: [design.md](./design.md)
> 対応要件定義書: [requirements.md](./requirements.md) v1.9
> 参考: [専門家レビュー](../../../docs/expert-reviews/2026-03-08-escalation-share-design-review.md)

---

## 1. 変更概要

| ID | 変更名 | 概要 |
|----|--------|------|
| C-01 | CPSTier 8段階化 | 3段階（normal/medium/maximum）→ 8段階（t0〜t7）、ピッチ 0〜+680 cent |
| C-02 | 背景色 CPSTier 単独制御 | BackgroundEffectView を CPSTier 単独グラデーション制御に変更（紺→紫→マゼンタ→橙赤） + ヒステリシス + クロスフェード |
| C-03 | 揺れ timeFactor 改善 + Reduce Motion | timeFactor の立ち上がり改善 + `UIAccessibility.isReduceMotionEnabled` 対応（maxShakeAmplitude=5.0pt 維持） |
| C-04 | シェア改善 | 一時ファイル URL 方式への移行（PHPhotoLibrary はシェアシート内の「画像を保存」で代替） |
| C-05 | スコアカードデザイン改善 | プレイヤー名・日付フォーマット・称号バッジの追加（CPS表示は削除） |
| C-06 | ホーム画面シェア導線 | ホーム画面から歴代ベスト・今日のベストのスコアカードをシェアできるボタンを追加 + 歴代ベスト日付表示 |
| C-07 | 要件定義書 v2.0 更新 | Appendix B 8段階化 + REQ-25/27/29, NFR-11/18, E2E-4/9/10、画面一覧・揺れ方式更新。REQ-28/E2E-11/E2E-12 削除（保存ボタン廃止） |
| C-08 | 保存ボタン削除 + 画像最適化 | 結果画面の保存ボタン削除、PHPhotoLibrary 関連コード削除、スコアカードからCPS削除、画像形式を PNG→JPEG(0.85) に変更 |

---

## 2. 変更点一覧

### C-01: CPSTier 8段階化

**理由:** 3段階では CPS 上昇に対するフィードバックが粗く、プレイヤーが速度向上を体感しにくい。専門家レビューで 8段階・50〜140 cent 間隔が推奨された。

**Before:**

```swift
// CPSTier.swift（実装値。要件定義書 Appendix B の値 0-4/5-14/15+ とは乖離あり）
enum CPSTier: CaseIterable {
    case normal   // CPS 0〜7  (mediumThreshold = 8)
    case medium   // CPS 8〜19 (maximumThreshold = 20)
    case maximum  // CPS 20+
}

// PitchConfig.swift
static let normal  = PitchConfig(pitchShift: 0)
static let medium  = PitchConfig(pitchShift: 200)
static let maximum = PitchConfig(pitchShift: 500)
```

> **注:** 実装の閾値（8/20）は要件定義書 Appendix B の閾値（5/15）と乖離している。v3 で 8段階化する際に要件と実装を統一する。

**After:**

```swift
// CPSTier.swift
enum CPSTier: Int, CaseIterable, Comparable {
    case t0 = 0  // CPS 0〜4
    case t1 = 1  // CPS 5〜7
    case t2 = 2  // CPS 8〜10
    case t3 = 3  // CPS 11〜14
    case t4 = 4  // CPS 15〜18
    case t5 = 5  // CPS 19〜22
    case t6 = 6  // CPS 23〜26
    case t7 = 7  // CPS 27+

    static func tier(for cps: Int) -> CPSTier {
        switch cps {
        case ..<5:  return .t0
        case ..<8:  return .t1
        case ..<11: return .t2
        case ..<15: return .t3
        case ..<19: return .t4
        case ..<23: return .t5
        case ..<27: return .t6
        default:    return .t7
        }
    }

    static func < (lhs: CPSTier, rhs: CPSTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// PitchConfig.swift
struct PitchConfig {
    let pitchShift: Float

    private static let table: [CPSTier: Float] = [
        .t0: 0, .t1: 60, .t2: 130, .t3: 220,
        .t4: 320, .t5: 430, .t6: 540, .t7: 680,
    ]

    static func config(for tier: CPSTier) -> PitchConfig {
        PitchConfig(pitchShift: table[tier] ?? 0)
    }
}
```

**影響ファイル:**

| ファイル | 変更内容 |
|---------|---------|
| `TapBurst/Models/CPSTier.swift` | enum 定義を 8 段階に変更、`Comparable` 準拠追加 |
| `TapBurst/Models/PitchConfig.swift` | 8 段階ピッチテーブルに変更 |
| `TapBurst/Models/ParticleConfig.swift` | 8 段階パーティクル設定に変更（t0〜t3 は低密度から中密度へ段階的、t4〜t7 は高密度） |
| `TapBurst/ViewModels/GameManager.swift` | `currentCPSTier` 初期値を `.t0` に変更 |
| `TapBurst/UIKit/GameTouchView.swift` | `ParticleConfig.config(for:)` 呼び出しは変更不要（インターフェース維持） |
| `TapBurst/Services/AudioService.swift` | `playTapSound(tier:)` は `PitchConfig.config(for:)` 経由のため変更不要 |
| `TapBurstTests/ModelsTests.swift` | CPSTier/PitchConfig/ParticleConfig のテストを 8 段階に更新 |

---

### C-02: 背景色 CPSTier overlay

**理由:** 現状の BackgroundEffectView は TimeStage のみで色が決まる。CPSTier による彩度・輝度の変化を加えることで、タップ速度に対する視覚フィードバックを強化する。専門家レビューで「TimeStage=色相、CPSTier=彩度・輝度」の責務分離が推奨された。

**Before:**

```swift
struct BackgroundEffectView: View {
    let timeStage: TimeStage
    // TimeStage のみでグラデーション色を決定
}
```

**After:**

```swift
struct BackgroundEffectView: View {
    let timeStage: TimeStage
    var cpsTier: CPSTier = .t0

    // TimeStage ベースグラデーション（既存）
    // + CPSTier オーバーレイ（opacity 0.0〜0.35、彩度・輝度を強調）
    // cpsTier 変化時のみ .animation(.easeInOut(duration: 0.2)) で遷移
}
```

**CPSTier overlay 設計:**
- overlay 色: TimeStage に応じた暖色系の Color（例: calm → 青白、warm → 紫、intense → 橙赤）
- overlay opacity: `t0=0.0`, `t1=0.05`, `t2=0.10`, `t3=0.15`, `t4=0.20`, `t5=0.25`, `t6=0.30`, `t7=0.35`
- 背景色の最大輝度は HSB 0.85 以下を維持（HUD 視認性確保）
- `drawingGroup()` は不使用（シンプルなグラデーション+overlay には不要）

**呼び出し元の変更:**

| ファイル | Before | After |
|---------|--------|-------|
| `GamePlayView.swift` | `BackgroundEffectView(timeStage: gameManager.currentTimeStage)` | `BackgroundEffectView(timeStage: gameManager.currentTimeStage, cpsTier: gameManager.currentCPSTier)` |
| `HomeView.swift` | `BackgroundEffectView(timeStage: .calm)` | `BackgroundEffectView(timeStage: .calm)` (cpsTier デフォルト .t0) |
| `ResultsView.swift` | `BackgroundEffectView(timeStage: .warm)` | `BackgroundEffectView(timeStage: .warm)` (cpsTier デフォルト .t0) |
| `FinishView.swift` | `BackgroundEffectView(timeStage: .warm)` | `BackgroundEffectView(timeStage: .warm)` (cpsTier デフォルト .t0) |
| `CountdownView.swift` | `BackgroundEffectView(timeStage: .calm)` | `BackgroundEffectView(timeStage: .calm)` (cpsTier デフォルト .t0) |

> デフォルト引数 `.t0` により、GamePlayView 以外の呼び出し元は変更不要。

**影響ファイル:**

| ファイル | 変更内容 |
|---------|---------|
| `TapBurst/Views/Components/BackgroundEffectView.swift` | `cpsTier` 引数追加、overlay レイヤー追加 |
| `TapBurst/Views/GamePlayView.swift` | `cpsTier:` 引数を追加 |

---

### C-03: 揺れ timeFactor 改善 + Reduce Motion

**理由:** 現行 `pow(elapsed/10.0, 3.0)` は序盤の立ち上がりが遅すぎる（5秒時点で 0.125）。また Apple HIG に基づく Reduce Motion 対応が未実装。

**Before:**

```swift
// GameManager.swift updateEffects()
let timeFactor = pow(normalizedElapsed, 3.0)
let shakeAmplitude = maxShakeAmplitude * CGFloat(tapRateFactor * timeFactor)

shakeOffset = CGSize(
    width: CGFloat.random(in: -shakeAmplitude...shakeAmplitude),
    height: CGFloat.random(in: -shakeAmplitude...shakeAmplitude)
)
```

**After:**

```swift
// GameManager.swift updateEffects()
let timeFactor = 0.18 + 0.82 * pow(normalizedElapsed, 1.6)
let shakeAmplitude = maxShakeAmplitude * CGFloat(tapRateFactor * timeFactor) * reduceMotionFactor

shakeOffset = CGSize(
    width: CGFloat.random(in: -shakeAmplitude...shakeAmplitude),
    height: CGFloat.random(in: -shakeAmplitude...shakeAmplitude)
)
```

**変更内容:**

| 項目 | Before | After |
|------|--------|-------|
| timeFactor 式 | `pow(normalizedElapsed, 3.0)` | `0.18 + 0.82 * pow(normalizedElapsed, 1.6)` |
| 0秒時点の timeFactor | 0.0 | 0.18 |
| 5秒時点の timeFactor | 0.125 | 0.45 |
| 10秒時点の timeFactor | 1.0 | 1.0 |
| maxShakeAmplitude | 5.0pt | 5.0pt（変更なし） |
| 揺れ方式 | フレームごとランダム | フレームごとランダム（変更なし。サイン波は V2-022 で不採用確定済み） |
| Reduce Motion | 未対応 | `UIAccessibility.isReduceMotionEnabled` 時に振幅を 50% に軽減 |

**Reduce Motion 実装:**

```swift
// GameManager.swift
private var reduceMotionFactor: CGFloat {
    UIAccessibility.isReduceMotionEnabled ? 0.5 : 1.0
}
```

**影響ファイル:**

| ファイル | 変更内容 |
|---------|---------|
| `TapBurst/ViewModels/GameManager.swift` | `updateEffects()` の timeFactor 式変更、`reduceMotionFactor` 追加 |

---

### C-04: シェア改善（PHPhotoLibrary + 一時ファイル URL）

**理由:** 現行は `UIImage` 直接渡しのため、AirDrop でのファイル名が不安定。また画像保存機能がない。専門家レビューで PHPhotoLibrary + 一時ファイル URL が推奨された。

**Before:**

```swift
// ResultsView.swift
let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
```

**After:**

```swift
// ShareService.swift (新規)
// 1. UIImage → 一時ファイル URL（TapBurst_{score}_{UUID}.png）
// 2. UIActivityViewController に URL を渡す
// 3. PHPhotoLibrary 保存ボタン（別途）は保存専用

// ResultsView.swift
// shareScorecard() を ShareService 経由に変更
```

**実装詳細:**

1. **一時ファイル URL 方式**: `FileManager.default.temporaryDirectory` に `TapBurst_{score}_{UUID}.png` で保存し、URL を `UIActivityViewController` に渡す。UUID を含めることで同スコア・異なるプレイヤー名での上書き競合を防止する
2. **一時ファイルのクリーンアップ**: ShareService 初期化時（= 次回シェア時）に、前回以前の一時ファイル（`TapBurst_*.png`）を削除する。アプリ起動時の掃除は不要（`tmp/` は OS が定期的にクリアするため）
3. **PHPhotoLibrary 保存**: `PHPhotoLibrary.shared().performChanges` + `PHAssetCreationRequest` で写真ライブラリに保存
4. **権限**: `NSPhotoLibraryAddUsageDescription` を Info.plist に追加、`PHPhotoLibrary.requestAuthorization(for: .addOnly)` で認可要求
5. **権限拒否時**: アラートで設定アプリへ誘導（`UIApplication.openSettingsURLString`）。シェア（Share Sheet）は権限不要で引き続き利用可能
6. **保存タイミング**: ユーザーが「保存」ボタンをタップした時（ジャストインタイム方式）

**影響ファイル:**

| ファイル | 変更内容 |
|---------|---------|
| `TapBurst/Services/ShareService.swift` | 新規作成。一時ファイル URL 生成、UIActivityViewController 表示、PHPhotoLibrary 保存 |
| `TapBurst/Views/ResultsView.swift` | `shareScorecard()` / `shareScore()` を `ShareService` 経由に変更、「保存」ボタン追加 |
| `TapBurst/Info.plist` | `NSPhotoLibraryAddUsageDescription` 追加 |
| `TapBurst/Localizable.xcstrings` | 保存関連の文言追加 |

---

### C-05: スコアカードデザイン改善

**理由:** 現行のスコアカードにはプレイヤー名・称号バッジが含まれず、シェア時の訴求力が弱い。

**Before:**

```
ScorecardView: ロゴ、スコア、称号テキスト、日付、アプリ名
```

**After:**

```
ScorecardView: ロゴ、プレイヤー名、スコア、称号バッジ（Capsule背景）、CPS、日付、アプリ名
```

**変更内容:**

1. **プレイヤー名**: スコア上部に表示。未設定時は非表示。表示上限 12文字（`.lineLimit(1)` + `.truncationMode(.tail)`）
2. **プレイヤー名入力**: 初回シェア時にシートで入力（ジャストインタイム方式）。入力済みの名前は `UserDefaults` に保存し次回以降デフォルト使用
3. **名前サニタイズ**: 先頭末尾の空白 trim、改行・制御文字除去、連続スペース圧縮、ゼロ幅文字・RTL オーバーライド文字フィルタリング。絵文字は許可
4. **称号バッジ**: Capsule 背景付きの称号表示
5. **CPS 表示**: スコアカードに CPS を追加
6. **日付フォーマット**: 既存の `.dateTime` を維持

**影響ファイル:**

| ファイル | 変更内容 |
|---------|---------|
| `TapBurst/Views/Components/ScorecardView.swift` | プレイヤー名・CPS・称号バッジの追加 |
| `TapBurst/Models/ScoreResult.swift` | `cps: Double` プロパティ追加（V3-085 で実施。C-05 の前提） |
| `TapBurst/ViewModels/GameManager.swift` | `endGame()` の ScoreResult 生成に `cps:` 引数追加（V3-085 で実施） |
| `TapBurst/Services/ScoreStore.swift` | `playerName` の保存・取得（UserDefaults） |
| `TapBurst/Views/PlayerNameInputView.swift` | 新規作成。名前入力シート |
| `TapBurst/Localizable.xcstrings` | 名前入力関連の文言追加 |

---

### C-06: ホーム画面シェア導線

**理由:** 現状はプレイ直後の結果画面でしかシェアできない。過去の歴代ベストをシェアしたいケースに対応する。

**前提条件（データモデル拡張）:**

現在の `ScoreStore` は `bestScore: Int` のみを保存しており、プレイ日時や CPS を再現できない。ホーム画面からのシェアでは要件（REQ-25: プレイ日時を含むスコアカード）を満たすため、**ベストスコア更新時にスナップショットを永続化する必要がある**。

```swift
// ScoreStore.swift に追加
struct BestScoreSnapshot: Codable {
    let score: Int
    let cps: Double
    let playedAt: Date?  // nil = レガシーレコード（v3以前のベスト更新で日時未記録）
}

// bestScore 更新時に同時保存
func updateIfNeeded(score: Int, cps: Double, playedAt: Date) -> Bool {
    // 既存の bestScore 更新ロジック + snapshot 保存
}

// ホームシェア用に復元
var bestScoreSnapshot: BestScoreSnapshot? { get }
```

- `BestScoreSnapshot` は `Codable` で UserDefaults に JSON 保存（`bestScoreSnapshotKey`）
- 既存の `bestScore: Int` は互換性のため維持（snapshot から score を取得するだけでなく、既存コードの影響を最小化）
- `playedAt` は `Date?`（optional）: v3以降のベスト更新時は必ず `Date()` を設定。レガシーレコードでは nil
- マイグレーション: snapshot が nil かつ bestScore > 0 の場合、`playedAt: nil`（日時不明）、CPS は `Double(score) / 10.0` で推定値を使用
- スコアカード上の表示: `playedAt` が nil の場合は日時欄を非表示とする（虚偽の日時を表示しない）

**Before:** ホーム画面にシェアボタンなし。`ScoreStore` は `bestScore: Int` のみ保存。

**After:** スコアパネル内に歴代ベストのシェアボタンを追加（ベストスコアが 0 より大きい場合のみ表示）。`ScoreStore` に `BestScoreSnapshot` を追加し、ベスト更新時にスナップショットを永続化。

**実装詳細:**
- シェアボタンタップ時に `ScoreStore.bestScoreSnapshot` から `ScoreResult` を復元し、`ShareService` 経由でスコアカード画像をシェア
- `isNewBest` は `false`
- プレイヤー名はスコアカードに含む（C-05 で実装済みの場合）

**影響ファイル:**

| ファイル | 変更内容 |
|---------|---------|
| `TapBurst/Services/ScoreStore.swift` | `BestScoreSnapshot` 構造体追加、`bestScoreSnapshot` 保存・取得、`updateIfNeeded` シグネチャ変更 |
| `TapBurst/ViewModels/GameManager.swift` | `endGame()` 内の `updateIfNeeded` 呼び出しに `cps:` `playedAt:` 引数追加 |
| `TapBurst/Views/HomeView.swift` | スコアパネル内にシェアボタン追加 |
| `TapBurst/Localizable.xcstrings` | ホーム画面シェアボタンの文言追加 |
| `TapBurstTests/ScoreStoreTests.swift` | snapshot 保存・復元・マイグレーションのテスト追加 |

---

### C-07: 要件定義書 v1.9 更新

**理由:** v3 変更仕様の新要件を要件定義書に反映し、正本として確定させる必要がある。

**変更内容:**

1. **Appendix B CPS軸エスカレーション 8段階化**: 3段階（通常/中/最大）→ 8段階（T0〜T7）。列は「段階 / リアルタイムCPS / 演出方向性」の3列（ピッチ値・想定プレイスタイル列は change-spec に留める）
2. **REQ-25 にプレイヤー名追加**: スコアカード画像の情報にプレイヤー名（設定済みの場合）を追加
3. **REQ-27 新設（ホーム画面シェア）**: ホーム画面から歴代ベストのスコアカードをシェアできるボタン
4. **REQ-28 新設（写真ライブラリ保存）**: 結果画面の保存ボタンで写真ライブラリに保存、権限要求・拒否時誘導
5. **REQ-29 新設（プレイヤー名入力）**: 初回シェア時に名前入力シート表示、12文字上限、ローカル保存
6. **NFR-18 新設（Reduce Motion）**: 視差効果を減らす設定ON時に画面揺れの振幅を50%に軽減
7. **NFR-11 永続化範囲拡張**: 自己ベストスコアに加えCPS・プレイ日時も永続化
8. **技術的制約「データ永続化」更新**: NFR-11 拡張に合わせた文言更新
9. **技術的制約「画面揺れパターン」更新**: sin波推奨→フレームごとランダム採用に統一（V2-022結果）
10. **US-07 拡張**: ユーザーストーリー文と完了条件にホーム画面シェアを追加
11. **画面一覧更新**: ホーム画面にシェアボタン、結果画面に保存ボタンを追加
12. **E2E-4 検証項目拡充**: CPS・プレイ日時を期待結果に追加
13. **E2E-9 追加**: ホーム画面シェアのE2Eテスト
14. **E2E-10 追加**: Reduce MotionのE2Eテスト
15. **E2E-11 追加**: 写真ライブラリ保存（許可パス）のE2Eテスト
16. **E2E-12 追加**: 写真ライブラリ権限拒否パスのE2Eテスト
17. **REQ-27 レガシーCPS明文化**: CPS はスコアから算出可能なためレガシーでも常に表示
18. **変更履歴に v1.9 追記**

**影響ファイル:**

| ファイル | 変更内容 |
|---------|---------|
| `.kiro/specs/tapburst-game/requirements.md` | Appendix B 8段階化、REQ-25/27/28/29、NFR-11/18、E2E-4/9/10/11/12、US-07拡張、画面一覧更新、技術的制約2件更新、変更履歴追記 |

---

## 3. 依存関係図

```
C-07 (要件定義書更新)
  |
  v
C-01 (CPSTier 8段階化)
  |
  +---> C-02 (背景色 CPSTier overlay) ---- C-01 の CPSTier 定義に依存
  |
  +---> C-05 (スコアカードデザイン改善) --- ScoreResult.cps に依存
  |       |
  |       v
  |     C-04 (シェア改善) ---------------- ShareService に依存
  |       |
  |       v
  |     C-06 (ホーム画面シェア導線) ------- C-04/C-05 + BestScoreSnapshot に依存
  |                                        ↑
  |           BestScoreSnapshot (V3-086) ---+  ← ScoreStore のモデル拡張が前提
  |
C-03 (揺れ改善 + Reduce Motion) ---------- 独立（C-01 とは無関係）
```

**並行可能な組み合わせ:**
- C-01 と C-03 は独立して並行実装可能
- C-02 は C-01 完了後に実装
- C-04/C-05 は ScoreResult.cps 追加（V3-085）完了後に実装
- C-06 は C-04/C-05 + BestScoreSnapshot（V3-086）完了後に実装
- C-07 は最初に実施（要件を先に確定させる）

---

## 4. 技術的制約

以下は本変更で新たに適用される制約。既存の制約（CLAUDE.md・requirements.md 記載）は省略。

| # | 制約 | 根拠 |
|---|------|------|
| TC-01 | ピッチ値は +680 cent を上限とする（+700〜800 cent が実用上限、+1200 以上はチップマンク化） | 専門家レビュー §1.3 |
| TC-02 | 隣接段階のピッチ差は最低 50 cent 以上を確保する（ゲーム中の実効 JND） | 専門家レビュー §1.2 |
| TC-03 | 背景色は CPSTier 単独制御（baseHSB 8段階テーブル）。最大輝度は HSB 0.85 以下。overlay 方式は廃止 | 専門家レビュー 2026-03-08 §6 |
| TC-04 | CPSTier 変化時は `.id(cpsTier).transition(.opacity)` でクロスフェード（色相補間を回避） | 専門家レビュー 2026-03-08 §7 |
| TC-05 | CPSTier ヒステリシス: 上昇 150ms / 下降 300ms 維持で確定。CPSTierFilter 構造体でロジック分離 | 専門家レビュー 2026-03-08 §7 |
| TC-06 | `drawingGroup()` はシンプルなグラデーションには不使用 | 専門家レビュー §2.4 |
| TC-07 | 揺れ方式はフレームごとランダムを維持（サイン波は V2-022 で不採用確定） | 開発履歴 |
| TC-08 | maxShakeAmplitude は 5.0pt 維持 | ユーザー確認済み |
| TC-09 | Reduce Motion 時は揺れ振幅を 50% に軽減（40〜60% の中間値） | Apple HIG + 専門家レビュー §3.3 |
| TC-10 | 画像保存は PHPhotoLibrary + `PHAssetCreationRequest` を使用 | 専門家レビュー §4.1 |
| TC-11 | シェアの activityItems には一時ファイル URL を使用（UIImage 直接渡し不可）。ファイル名は `TapBurst_{score}_{UUID}.png` とし、同スコア・異内容での衝突を防止 | 専門家レビュー §4.4 |
| TC-12 | プレイヤー名の表示上限は 12 文字 | 専門家レビュー §5.2 |
| TC-13 | 名前入力は初回シェア時にシートで実施（ジャストインタイム方式） | 専門家レビュー §5.1 |

---

## 5. タスクリスト

### Phase V3-A: 要件更新 + モデル変更

- [x] **V3-010** 要件定義書を v1.9 に更新 (C-07)
  - Appendix B CPS軸エスカレーションを8段階に更新
  - REQ-25 にプレイヤー名を追加
  - REQ-27（ホーム画面シェア）新設
  - REQ-28（写真ライブラリ保存）新設
  - REQ-29（プレイヤー名入力）新設
  - NFR-18（Reduce Motion）新設
  - NFR-11 永続化範囲拡張
  - E2E-4 検証項目拡充、E2E-9/E2E-10/E2E-11/E2E-12 追加
  - 画面一覧更新、揺れ方式の技術的制約をV2-022結果に統一
  - 変更履歴に v1.9 追記
  - 設計書 `design.md` の CPSTier/PitchConfig セクションも更新

- [x] **V3-020** `TDD` CPSTier.swift を 8段階に変更 (C-01)
  - enum case: `.t0`〜`.t7`（`Int` rawValue, `Comparable` 準拠）
  - `tier(for:)` を 8段階の閾値マッピングに変更
  - テスト: 全 17 境界値（-1,0,4→t0, 5,7→t1, 8,10→t2, 11,14→t3, 15,18→t4, 19,22→t5, 23,26→t6, 27,100→t7）
  - テスト: 負の CPS 入力（-1）が `.t0` にマッピングされることを明示的に検証

- [x] **V3-030** `TDD` PitchConfig.swift を 8段階に変更 (C-01)
  - 8段階ピッチテーブル: 0, 60, 130, 220, 320, 430, 540, 680
  - Dictionary lookup (`table[tier] ?? 0`) → switch 全ケース網羅方式に変更（ケース追加時のコンパイル検出を保証）
  - テスト: 各 tier のピッチ値が設計値と一致

- [x] **V3-040** `TDD` ParticleConfig.swift を 8段階に変更 (C-01)
  - t0〜t3: 低密度〜中密度（段階的に birthRate/scale/velocity を増加）
  - t4〜t7: 高密度（既存 maximum 相当を基準に段階的に強化）
  - iPhone SE 3rd gen のパフォーマンス予算内（同時 emitter 5、birthRate 最大 64）
  - テスト: 各 tier の birthRate/scale/lifetime/velocity が設計値と一致
  - テスト: 全 tier で birthRate <= 64 を回帰テストとして検証（iPhone SE 3rd gen 上限）
  - テスト: tier 間で birthRate/scale が単調増加であること

- [x] **V3-050** GameManager の CPSTier 初期値を `.t0` に変更 (C-01)
  - `currentCPSTier` 初期値: `.normal` → `.t0`
  - `startGame()`, `beginPlaying()`, `endGame()`, `handleBackground()` 内の `.normal` → `.t0`

### Phase V3-B: 視覚演出改善

- [x] **V3-060** 背景色を CPSTier 単独制御に変更 (C-02 → 専門家レビュー 2026-03-08 改定)
  - 旧方式（TimeStage ベースグラデーション + CPSTier overlay）を廃止
  - CPSTier.baseHSB computed property 追加（8段階HSBテーブル: 紺→紫→マゼンタ→橙赤）
  - gradientColors(for:) で2色導出（topLeading: s-0.06,b-0.08 / bottomTrailing: h-0.02,s+0.04,b+0.08）
  - `.id(cpsTier).transition(.opacity)` で色相補間を回避（クロスフェード方式）
  - cpsTier の `.animation` modifier 削除（GameManager の withAnimation で駆動）
  - vignette（RadialGradient）は TimeStage 制御を維持
  - overlayColors/overlayOpacity/overlayTransitionDuration 関連コード削除
  - CPSTierFilter 構造体を新規作成（ヒステリシスロジックをテスト可能な形で分離）
    - 上昇: 150ms 維持で確定（withAnimation(.easeOut(duration: 0.14))）
    - 下降: 300ms 維持で確定（withAnimation(.easeInOut(duration: 0.26))）
    - 同tierなら pending リセット、異なるtierは pending タイマーリセット
  - GameManager: pendingCPSTier/pendingTierSince → CPSTierFilter に委譲
  - GameManager: registerTap()/displayLinkFired() の直接代入を updateCPSTierWithHysteresis() に置換
  - GameManager: startGame()/beginPlaying()/endGame()/handleBackground() で tierFilter.reset()
  - テスト: baseHSB t0/t7 値検証 + CPSTierFilter ヒステリシス 6件（上昇未達/確定、下降未達/確定、pending解除、tier変更時リセット、reset）
  - 参照: docs/expert-reviews/2026-03-08-cps-background-color-escalation-review.md

- [x] **V3-070** GamePlayView に cpsTier 引数を追加 (C-02)
  - `BackgroundEffectView(timeStage:cpsTier:)` 呼び出しに `gameManager.currentCPSTier` を渡す
  - BackgroundEffectView 内部で `allowsHitTesting(false)` を適用済みのため、GamePlayView 側の重複修飾子を除去

- [x] **V3-080** 揺れ timeFactor 改善 + Reduce Motion (C-03)
  - timeFactor 式: `0.18 + 0.82 * pow(normalizedElapsed, 1.6)`
  - `reduceMotionFactor` computed property 追加（Reduce Motion ON 時: 0.5）
  - maxShakeAmplitude: 5.0pt 維持
  - 揺れ方式: フレームごとランダム維持

### Phase V3-C: シェア機能改善

- [x] **V3-085** `TDD` ScoreResult に `cps: Double` プロパティを追加 (C-05 前提)
  - `ScoreResult.swift`: `cps: Double` プロパティ追加
  - `GameManager.endGame()`: ScoreResult 生成時に `cps` を算出して渡す（`Double(score) / gameDuration`）
  - `ResultsView` Preview, `ScorecardView` Preview: `cps:` 引数追加
  - `generateScorecardImage()` 呼び出し元: 変更不要（ScoreResult 経由）
  - テスト: ScoreResult 生成時に cps が正しく設定されることを検証

- [x] **V3-086** `TDD` ScoreStore に BestScoreSnapshot を追加 (C-06 前提)
  - `BestScoreSnapshot: Codable` 構造体（score, cps, playedAt: Date?）
  - `playedAt` は optional: v3以降のベスト更新時は `Date()` を設定、レガシーレコードは nil
  - `bestScoreSnapshot: BestScoreSnapshot?` computed property（UserDefaults JSON）
  - `updateIfNeeded(score:cps:playedAt:) -> Bool`: 既存 bestScore 更新 + snapshot 保存
  - `resetAll()`: snapshot も削除
  - マイグレーション: snapshot nil かつ bestScore > 0 → `playedAt: nil`、CPS は推定値で snapshot 作成
  - テスト: snapshot 保存・復元、resetAll 後に nil、マイグレーション動作（playedAt が nil であること）
  - `GameManager.endGame()`: `updateIfNeeded` 呼び出しに `cps:` `playedAt:` 引数追加

- [x] **V3-090** ShareService.swift を新規作成 (C-04)
  - `shareScorecard(image:score:from:)`: UIImage → 一時ファイル URL（`TapBurst_{score}_{UUID}.png`） → UIActivityViewController
  - シェア前に前回以前の一時ファイル（`TapBurst_*.png`）を掃除（`try?` で非致命的に実行）
  - `saveToPhotoLibrary(image:)`: PHPhotoLibrary 保存（async/await）、権限判定は `.authorized` のみ
  - `requestPhotoLibraryPermission()`: `.addOnly` 認可要求
  - 権限拒否時: 設定アプリ誘導アラート

- [x] **V3-091** `InfoPlist.xcstrings` から `NSPhotoLibraryAddUsageDescription` を削除 (C-08)
  - 保存ボタン廃止に伴い PHPhotoLibrary 権限が不要になったため

- [x] **V3-100** ScorecardView にプレイヤー名・CPS・称号バッジを追加 (C-05)
  - プレイヤー名: スコア上部、12文字上限、未設定時は非表示
  - CPS 表示: スコア下部（ScoreResult.cps を使用 — V3-085 で追加済み）
  - 称号バッジ: Capsule 背景付き

- [x] **V3-101** PlayerNameInputView.swift を新規作成 (C-05)
  - `Submission` enum（`.save(String)` / `.skip`）+ 単一 `onComplete` コールバック方式
  - 名前入力シート（TextField + 保存/スキップボタン）
  - 文字数制限は UI 側で 12 文字に制限（`onChange` で `prefix`）、サニタイズは ScoreStore 側で実施
  - 絵文字は許可

- [x] **V3-102** `TDD` ScoreStore にプレイヤー名の保存・取得を追加 (C-05)
  - `playerName: String?` computed property（UserDefaults）
  - `savePlayerName(_:)` メソッド（サニタイズ処理込み）
  - テスト: 保存・取得、nil 初期値、サニタイズ（空白 trim、制御文字除去、連続スペース圧縮、ゼロ幅文字フィルタ、絵文字許可、空文字→nil）

- [x] **V3-103** GameManager に `playerName`, `bestScoreSnapshot`, `savePlayerName(_:)` を公開 (C-05/C-06)
  - View から ScoreStore を直接参照せず、GameManager 経由でアクセスする設計に統一
  - `playerName: String?` — ScoreStore の computed property を委譲
  - `bestScoreSnapshot: BestScoreSnapshot?` — ScoreStore の computed property を委譲
  - `savePlayerName(_:)` — ScoreStore のメソッドを委譲

- [x] **V3-110** ResultsView を ShareService 経由に変更 (C-04/C-08)
  - `shareScore()` を `ShareService.shareScorecard()` 経由に変更
  - 保存ボタン削除（シェアシート内の「画像を保存」で代替）
  - 結果画面は3ボタン構成（リトライ/シェア/ホーム）
  - 初回シェア時に PlayerNameInputView をシートで表示（`.sheet(onDismiss:)` パターン）
  - ScoreStore の直接参照を廃止し、GameManager 経由に統一

- [x] **V3-120** HomeView にシェア導線を追加 (C-06)
  - スコアパネル内に歴代ベストシェアアイコンボタン（`bestScore > 0` 時のみ表示、44x44）
  - 今日のベストシェアアイコンボタン（`todayBestScore > 0` 時のみ表示、36x36）
  - ShareTarget enum（`.allTimeBest` / `.todayBest`）で分岐
  - `gameManager.bestScoreSnapshot` から ScoreResult を復元してシェア（V3-086 で永続化済み）
  - 歴代ベストの称号下に達成日時を表示（レガシーの場合は非表示）
  - 初回シェア時に PlayerNameInputView をシートで表示（`.sheet(onDismiss:)` パターン）
  - ScoreStore の直接参照を廃止し、GameManager 経由に統一
  - VoiceOver 対応（label, hint）

### Phase V3-D: ローカライゼーション + ドキュメント

- [x] **V3-130** Localizable.xcstrings に v3 文言を追加
  - 保存ボタン: `results.save`, `results.save_success`, `results.save_denied`, `results.save_failed`
  - 名前入力: `player_name.title`, `player_name.message`, `player_name.placeholder`, `player_name.save`, `player_name.skip`
  - ホームシェア: `home.share_best`, `a11y.home.share_best_hint`
  - 権限: `photo_library.denied_title`, `photo_library.denied_message`, `photo_library.open_settings`
  - 保存ヒント: `a11y.results.save_hint`
  - 設定誘導: `settings.open`
  - キャンセル: `common.cancel`

---

## 6. 実装順序の根拠

```
V3-010 (要件更新)
   ↓ 要件確定を先行
V3-020〜V3-050 (CPSTier 8段階化 = Phase V3-A)
   ↓ モデル層の変更が全ての上位レイヤーの前提
V3-060〜V3-080 (視覚演出 = Phase V3-B)
   ↓ モデル変更完了後、BackgroundEffectView と揺れを改善
V3-085〜V3-086 (ScoreResult.cps + BestScoreSnapshot = Phase V3-C 前半)
   ↓ データモデル拡張が C-04/C-05/C-06 の前提
V3-090〜V3-120 (シェア機能 = Phase V3-C 後半)
   ↓ データモデル確定後、シェア機能を実装
V3-130 (ローカライゼーション = Phase V3-D)
   ↓ UI文言が確定してから一括追加
```

1. **V3-010 を最初に**: 設計原則「要件を先に更新し、設計書との整合性を確認してから実装」に従う
2. **V3-A（モデル層）を先行**: CPSTier の 8段階化は C-02, C-04, C-05 の前提。モデル層を先に安定させることで上位レイヤーの手戻りを防ぐ
3. **V3-B と V3-C は順序固定**: V3-B は GameManager の CPSTier を使用するため V3-A 完了後。V3-C は ScoreResult.cps と BestScoreSnapshot を含むため V3-A 完了後
4. **V3-085/V3-086 を V3-C の先頭に**: ScoreResult.cps 追加は ScorecardView・GameManager・Preview に波及し、BestScoreSnapshot は C-06 の前提条件。データモデル変更を先に安定させることでビルド破壊を防ぐ
5. **V3-080（揺れ改善）は V3-B に含む**: CPSTier とは独立だが、視覚演出の改善としてまとめて実施する方が検証効率が高い
6. **V3-D は最後**: 全 UI 変更が確定してから文言を一括追加する

---

## 検証チェックリスト

- [ ] ビルド成功（`xcodebuild build`）
- [ ] 全テスト通過（`xcodebuild test`）
- [ ] CPSTier 8段階: 各段階の閾値でピッチ・パーティクルが変化することを実機確認
- [ ] 背景色: CPSTier 上昇に伴い背景が紺→紫→マゼンタ→橙赤に変化することを実機確認
- [ ] 背景色: tier 境界でチラつかないこと（ヒステリシス）を実機確認
- [ ] 背景色: タップを止めると緩やかに色が戻ること（0.26秒）を実機確認
- [ ] 背景色: 白文字HUDが全tier帯で読めることを実機確認
- [ ] 揺れ: 序盤（0〜3秒）で揺れが知覚できることを実機確認
- [ ] Reduce Motion: 設定 ON 時に揺れが軽減されることを実機確認
- [ ] シェア: 一時ファイル URL 方式で AirDrop/LINE/X にスコアカードが送信できることを実機確認
- [ ] 画像保存: PHPhotoLibrary に保存できることを実機確認
- [ ] 権限拒否: 写真ライブラリ権限拒否時に設定アプリ誘導が表示されることを実機確認
- [ ] スコアカード: プレイヤー名・CPS・称号バッジが正しく表示されることを実機確認
- [ ] ホームシェア: 歴代ベストのスコアカードがシェアでき、プレイ日時が正しいことを実機確認
- [ ] BestScoreSnapshot: ベスト更新 → アプリ再起動 → ホームシェアで日時・CPS が復元されていることを確認
- [ ] マイグレーション: v2 からの更新で snapshot なし・bestScore ありの場合に推定値で動作することを確認
- [ ] iPhone SE 3rd gen: 60fps 維持、レイアウト崩れなし
