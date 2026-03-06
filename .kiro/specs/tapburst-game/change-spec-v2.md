# TapBurst v2 変更仕様書

> ベース: requirements.md v1.5 / design.md v1.2
> 作成日: 2026-03-06
> ステータス: ドラフト
> 専門家レビュー: docs/expert-reviews/2026-03-06-v2-game-mechanics-ux-review.md

---

## 変更概要

| # | 変更名 | 種別 | 影響範囲 |
|---|--------|------|----------|
| C-01 | Finish画面の追加 | 新規 | GamePhase, GameManager, ContentView, 新規FinishView |
| C-02 | 1フレーム1カウント化 | 変更 | TouchDetectionView, GameManager, GameSession |
| C-03 | CPS表示・同時タッチ表示の削除 | 削除 | ResultsView, ScorecardView, ScoreResult, GameSession, Localizable.xcstrings |
| C-04 | 画面揺れの2軸制御化 | 変更 | GameManager, TimeStage(廃止対象検討) |
| C-05 | パーティクル演出の強化 | 変更 | ParticleConfig, TouchDetectionView |

### 削除される機能

- 結果画面の CPS（秒速平均）表示
- 結果画面の最大同時タッチ数表示
- スコアカード画像の CPS 表示
- ScoreResult の `cps`, `maxSimultaneousTouches` プロパティ
- GameSession の `maxSimultaneousTouches` プロパティ
- 「残り2秒で揺れ開始」のTimeStage.intense依存の揺れ制御
- 毎フレームランダム方向の揺れパターン

---

## C-01: Finish画面の追加

### 背景

ゲーム終了後、タップ連打の勢いが止まらず、直後の結果画面のボタン（「もう1回」「シェア」「ホームに戻る」）を誤タップする問題がある。

### 仕様

#### GamePhase の変更

```
変更前: .home → .countdown → .playing → .results
変更後: .home → .countdown → .playing → .finish → .results
```

`GamePhase` enum に `.finish` case を追加する。

#### FinishView の仕様

| 項目 | 値 |
|------|-----|
| 表示時間 | 1.5秒（自動遷移、プレイテストで調整可） |
| 表示内容 | 「FINISH!」テキスト + 最終スコア（カウントアップアニメーション） |
| ボタン | なし |
| タッチ受付 | 完全無効 |
| 背景 | BackgroundEffectView（.warm） |

#### スコアカウントアップアニメーション

| 項目 | 値 |
|------|-----|
| 所要時間 | 0.85秒 |
| イージング | easeOut（終盤減速） |
| 開始値 | 0 |
| 終了値 | 最終スコア |

#### タッチ無効化の実装

タッチの無効化はUIView側（入力の最上流）で行う:

1. `TouchDetectionView.touchesBegan` の先頭で `guard gamePhase == .playing else { return }` — 入力源で遮断
2. FinishView の SwiftUI 側でも `allowsHitTesting(false)` — 二重防御

#### 画面遷移タイミング

1. ゲームタイマー10秒到達 → `phase = .finish`
2. `finish` SE 再生
3. スコアカウントアップアニメーション（0.85秒）
4. 残り0.65秒は最終スコア表示のまま待機
5. 1.5秒経過 → `phase = .results`（自動遷移）

#### 影響する既存要件

| 要件ID | 変更内容 |
|--------|----------|
| REQ-9 | 「結果画面へ遷移」→「Finish画面へ遷移」に変更 |

#### ローカライゼーション

| キー | 英語 | 日本語 |
|------|------|--------|
| `finish.title` | FINISH! | FINISH! |

---

## C-02: 1フレーム1カウント化

### 背景

同時マルチタッチ（最大5本指）が有効な現状では、5本指同時タップが最強戦略となり、「指を高速に交互に動かす」というコアの楽しさが損なわれている。

### 仕様

#### スコア加算ルール

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| 加算単位 | touchesBegan の指の本数（最大5） | 1回の有効タップにつき1 |
| 有効タップ判定 | なし（全タップ即加算） | 前回の有効タップから 16.67ms（1/60秒）以上経過 |
| 理論上限 | なし（5指 × 60fps = 3000/10秒） | 600/10秒（60tps × 10秒） |
| 加算タイミング | touchesBegan 内で即座に加算 | touchesBegan 内でタイムスタンプ比較し、条件を満たせば即加算 |

#### 実装方式: タイムスタンプ比較

```
touchesBegan で呼ばれるたびに:
  now = CACurrentMediaTime()
  if now - lastValidTapTime >= minTapInterval (16.67ms):
    score += 1
    lastValidTapTime = now
```

- `minTapInterval` は `1.0 / 60.0`（16.67ms）として型内部に定義
- CADisplayLink のフレームレートに依存しない（ProMotion 120Hz 端末でも理論上限は同じ600）
- フレーム落ちの影響を受けない

#### タッチ検出の変更

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| isMultipleTouchEnabled | true | true（維持） |
| touchesBegan のコールバック | `onTaps(count, positions)` | `onTap(positions)` — countは常に1（有効時のみコール） |
| パーティクル生成 | 全タッチ位置 | 全タッチ位置（維持。スコアは+1だがパーティクルは全指に生成） |

#### GameSession の変更

| プロパティ | 変更 |
|-----------|------|
| `maxSimultaneousTouches` | 削除 |
| `tapTimestamps` | 維持（CPS計算に使用。内部演出制御用） |
| `lastValidTapTime` | 新規追加（TimeInterval） |

#### CPSTier 閾値の見直し

1フレーム1カウントにより、CPS（直近1秒のタップ数）の実用範囲が変わる。
マルチタッチがスコアに寄与しないため、CPS上限は理論上60tps。

| Tier | 変更前 | 変更後 | 根拠 |
|------|--------|--------|------|
| normal | 0〜4 | 0〜7 | 単指タップ平均（6-7tps）以下 |
| medium | 5〜14 | 8〜19 | 複数指交互の本気タップ帯 |
| maximum | 15以上 | 20以上 | 熟練者のみ到達する高速帯 |

#### 影響する既存要件

| 要件ID | 変更内容 |
|--------|----------|
| REQ-6 | 「接触した指の本数分だけスコアを加算」→「1回の有効タップにつき1を加算（最小間隔16.67ms）」 |
| REQ-7 | 「5点を全てカウント対象」→ 削除（スコアカウントは1フレーム1回） |
| NFR-2 | 「5本指の同時タップを漏れなくカウント（入力ドロップ率0%）」→ 削除 |
| E2E-5 | 「5本指で同時に画面をタップする → 5カウント」→ 削除 |

---

## C-03: CPS表示・同時タッチ表示の削除

### 背景

- CPS（秒速平均）: 10秒固定のため `スコア ÷ 10` なだけで情報価値が薄い
- 最大同時タッチ数: 1フレーム1カウント化により意味を失う

### 仕様

#### ScoreResult の変更

| プロパティ | 変更 |
|-----------|------|
| `cps: Double` | 削除 |
| `maxSimultaneousTouches: Int` | 削除 |

変更後:
```
ScoreResult {
    score: Int
    title: TitleDefinition
    isNewBest: Bool
    playedAt: Date
}
```

#### ResultsView の変更

| 表示項目 | 変更 |
|----------|------|
| スコア | 維持 |
| CPS（秒速平均） | 削除 |
| 最大同時タッチ数 | 削除 |
| 称号 | 維持 |
| NEW BEST! | 維持 |

結果画面のレイアウトは HStack 2カラム構成を維持。左カラムの表示項目が減るため、スコアと称号をより大きく表示する。

#### ScorecardView の変更

| 表示項目 | 変更 |
|----------|------|
| ロゴ | 維持 |
| スコア | 維持 |
| CPS | 削除 |
| 称号 | 維持 |
| プレイ日時 | 維持 |
| アプリ名 | 維持 |

#### Localizable.xcstrings の変更

| キー | 変更 |
|------|------|
| `results.cps` | 削除 |
| `results.max_touches` | 削除 |

#### 影響する既存要件

| 要件ID | 変更内容 |
|--------|----------|
| REQ-16 | 「最終タップ数・秒速平均（CPS）・最大同時タッチ数を表示」→「最終タップ数を表示」 |
| REQ-25 | スコアカード画像の情報から「CPS」を削除 |
| US-04 完了条件 | 「4つの指標」→「2つの指標（タップ数・称号）」 |
| E2E-1 期待結果 | 「スコア・CPS・最大同時タッチ数・称号が表示」→「スコア・称号が表示」 |

#### 内部での CPS 利用

CPS は内部演出制御（パーティクル段階、揺れ制御）で引き続き使用する。`currentCPS` プロパティは GameManager 内に維持するが、結果画面・スコアカードには表示しない。

---

## C-04: 画面揺れの2軸制御化

### 背景

現在の揺れ制御は `TimeStage.intense`（経過8秒以降）でのみ発動し、振幅 ±3pt を毎フレームランダム方向に適用する単純な方式。以下の問題がある:

1. 8秒まで揺れがゼロで盛り上がりに欠ける
2. タップレートと揺れが無関係で、プレイヤーの頑張りが演出に反映されない
3. 毎フレームランダム方向はノイズ的な「ジャダー」になり不快

### 仕様

#### 2軸の定義

**軸1: タップレート係数 (tapRateFactor)**

| 項目 | 値 |
|------|-----|
| 入力 | currentCPS（直近1秒間のタップ数） |
| 正規化上限 | 20 tps（この値以上は 1.0 にクランプ） |
| 計算式 | `min(1.0, Double(currentCPS) / 20.0)` |
| 範囲 | 0.0〜1.0 |

**軸2: 時間経過係数 (timeFactor)**

| 項目 | 値 |
|------|-----|
| 入力 | elapsed（ゲーム開始からの経過時間） |
| カーブ | 3乗（pow） |
| 計算式 | `pow(elapsed / gameDuration, 3)` |
| 範囲 | 0.0〜1.0 |

数値例:

| 経過時間 | timeFactor |
|----------|-----------|
| 0秒 | 0.000 |
| 3秒 | 0.027 |
| 5秒 | 0.125 |
| 6秒 | 0.216 |
| 8秒 | 0.512 |
| 9秒 | 0.729 |
| 10秒 | 1.000 |

#### 合成方式

```
shakeAmplitude = maxAmplitude * tapRateFactor * timeFactor
```

| 項目 | 値 |
|------|-----|
| 合成方式 | 乗算 |
| maxAmplitude | 5.0 pt |

乗算により:
- タップしなければ後半でも揺れない（プレイヤーの一体感）
- 序盤はどんなに速くタップしても揺れは微小（timeFactor が小さい）
- 後半 + 高レートで初めて最大振幅に到達

#### 揺れパターン: sin波ベース

毎フレームランダムを廃止し、X軸・Y軸で異なる周波数のsin波を使用する。

```
shakeFrequencyX = 12.0  // ラジアン/秒 (約1.9Hz)
shakeFrequencyY = 15.6  // ラジアン/秒 (約2.5Hz) — X と非同期にするため

offsetX = sin(elapsed * shakeFrequencyX) * shakeAmplitude
offsetY = sin(elapsed * shakeFrequencyY) * shakeAmplitude * 0.6  // Y軸は控えめ
```

- X/Y の周波数比を非整数（12.0 : 15.6 = 1 : 1.3）にすることでリサージュ図形的な「物理的な振動」感を演出
- Y軸を 0.6 倍に抑えることで、横揺れ主体の自然な揺れに

#### フラッシュ演出

フラッシュ演出は TimeStage ベースを維持する（変更なし）。

| TimeStage | フラッシュ |
|-----------|-----------|
| calm (0〜5秒) | なし |
| warm (5〜8秒) | なし |
| intense (8〜10秒) | 0.7秒間隔、opacity 0.3 |

#### GameManager の変更

| プロパティ/定数 | 変更 |
|----------------|------|
| `shakeAmplitude: 3.0` | → `maxShakeAmplitude: 5.0` |
| `updateEffects(elapsed:)` | 2軸計算 + sin波パターンに全面書き換え |

#### 影響する既存要件

TimeStage 自体は背景グラデーション遷移とフラッシュに引き続き使用するため、enum は維持する。揺れ制御のみ TimeStage 依存から2軸制御に移行する。

---

## C-05: パーティクル演出の強化

### 背景

現在のパーティクルは `scaleRange=0.1` でほぼ均一サイズ、`velocity=120` で局所的な拡散にとどまっている。レート上昇時に画面全体に大きく広がる演出が不足している。

### 仕様

#### ParticleConfig の変更

| プロパティ | normal | medium | maximum | 備考 |
|-----------|--------|--------|---------|------|
| birthRate | 30 → 30 | 48 → 45 | 64 → 60 | 若干調整 |
| scale | 0.5 → 0.5 | 0.75 → 0.75 | 1.0 → 1.0 | 維持 |
| scaleRange | (なし) → 0.2 | (なし) → 0.35 | (なし) → 0.5 | 新規。base の ±40〜50% |
| velocity | (なし) → 120 | (なし) → 250 | (なし) → 500 | 新規。medium以上で拡散を拡大 |
| velocityRange | (なし) → 40 | (なし) → 80 | (なし) → 200 | 新規。velocity の約30〜40% |
| lifetime | 0.3 → 0.3 | 0.4 → 0.45 | 0.5 → 0.55 | 若干延長 |
| scaleSpeed | (なし) → -0.5 | (なし) → -0.8 | (なし) → -1.0 | 新規。縮みながら消える |
| color | (なし) → 白 | (なし) → オレンジ | (なし) → 黄赤 | 新規。Tier別の色変化 |

#### パフォーマンス試算（iPhone SE 基準）

同時パーティクル数 = birthRate x lifetime x 同時エミッター数(5)

| Tier | 同時パーティクル数 |
|------|-------------------|
| normal | 30 x 0.3 x 5 = 45 |
| medium | 45 x 0.45 x 5 = 101 |
| maximum | 60 x 0.55 x 5 = 165 |

安全上限（1000個）に対して十分な余裕がある。

#### CAEmitterCell の色指定

CPSTier 変更時はセルを新規作成し `emitterCells` を差し替える（動的変更はキャッシュ不整合リスクがあるため）。

| Tier | color (RGBA) |
|------|-------------|
| normal | 白 (1.0, 1.0, 1.0, 0.95) |
| medium | オレンジ (1.0, 0.7, 0.2, 0.95) |
| maximum | 黄赤 (1.0, 0.8, 0.2, 0.95) |

#### TouchDetectionView の変更

- `spawnParticleEmitter(at:)` で ParticleConfig の新プロパティ（velocity, velocityRange, scaleRange, scaleSpeed, color）を CAEmitterCell に適用
- Tier 変更時の色切替は、次のパーティクル生成時から自動的に新色が適用される（既存パーティクルは生成時の色で消える）

---

## 称号テーブル v2

### 変更前（上限なし、マルチタッチ前提）

| スコア範囲 | 称号 |
|-----------|------|
| 0〜49 | ウォーミングアップ |
| 50〜99 | なかなかやるね |
| 100〜199 | スピードスター |
| 200〜299 | マシンガンフィンガー |
| 300〜399 | 音速の指先 |
| 400〜499 | 人間やめてる |
| 500以上 | 神の領域 |

### 変更後（理論上限600、1フレーム1カウント）

> 注: 以下はドラフト値。プレイテストの実データに基づき境界値を調整する。

| スコア範囲 | 称号（日本語） | 称号（英語） | 想定層 |
|-----------|--------------|-------------|--------|
| 0〜49 | ウォーミングアップ | Warming Up | 初心者（〜5 tps） |
| 50〜99 | なかなかやるね | Not Bad | 一般ユーザー（5〜10 tps） |
| 100〜159 | スピードスター | Speed Star | ゲーム慣れ（10〜16 tps） |
| 160〜219 | マシンガンフィンガー | Machine Gun Finger | 熟練者（16〜22 tps） |
| 220〜289 | 音速の指先 | Sonic Fingertips | 上級者（22〜29 tps） |
| 290〜369 | 人間やめてる | Beyond Human | 超人域（29〜37 tps） |
| 370以上 | 神の領域 | God Tier | 理論限界への挑戦（37+ tps） |

称号名は変更なし（既存ローカライゼーションキーを再利用）。境界値のみ変更。

---

## 技術的制約

以下は2026-03-06の専門家レビュー（docs/expert-reviews/2026-03-06-v2-game-mechanics-ux-review.md）で確定した技術的制約である。

1. **スコア加算のデバイス公平性**: スコア加算は時間ベース（最小間隔 16.67ms = 1/60秒）で制御する。CADisplayLink のフレームレート（60Hz/120Hz）に依存させない。`preferredFrameRateRange` での60fps固定は非推奨（ProMotionの滑らかな描画を犠牲にするため）
2. **フェーズ遷移時のタッチ無効化**: `allowsHitTesting(false)` だけでは UIViewRepresentable 経由のタッチを防げない。`touchesBegan` の先頭でゲームフェーズを確認し、`.playing` 以外ではイベントを破棄する
3. **画面揺れパターン**: 毎フレームランダム方向は「ノイズ的ジャダー」になり不快。X/Y 異周波数の sin 波合成（リサージュ図形的アプローチ）を使用する
4. **CAEmitterCell.scaleSpeed**: 線形変化のみ。「膨張→収縮」は単一セルでは不可。「大きめ scale + 負の scaleSpeed」で「縮みながら消える」方式を使用
5. **CAEmitterCell.color の動的変更**: Core Animation キャッシュとの不整合リスクあり。Tier 変更時はセルを新規作成し emitterCells を差し替える
6. **パーティクル同時数の安全上限**: iPhone SE 3rd gen (A15) 基準で同時1000個以下を目安とする
7. **人間のタップ速度**: 単指10秒タッピングの学術値は平均 5.5〜7.4 tps。称号テーブルの境界値はプレイテストの実データで調整必須

---

## 影響する既存ファイル一覧

### モデル

| ファイル | 変更内容 |
|---------|----------|
| `Models/GamePhase.swift` | `.finish` case 追加 |
| `Models/GameSession.swift` | `maxSimultaneousTouches` 削除、`lastValidTapTime` 追加 |
| `Models/ScoreResult.swift` | `cps`, `maxSimultaneousTouches` 削除 |
| `Models/TitleDefinition.swift` | 境界値の変更（7段階は維持） |
| `Models/CPSTier.swift` | 閾値変更（5/15 → 8/20） |
| `Models/ParticleConfig.swift` | velocity, velocityRange, scaleRange, scaleSpeed, color 追加 |

### ViewModel

| ファイル | 変更内容 |
|---------|----------|
| `ViewModels/GameManager.swift` | Finish フェーズ追加、1フレーム1カウント化、2軸揺れ制御、endGame → finish 遷移 |

### Views

| ファイル | 変更内容 |
|---------|----------|
| `Views/FinishView.swift` | 新規作成 |
| `Views/ResultsView.swift` | CPS・同時タッチ行削除、レイアウト調整 |
| `Views/Components/ScorecardView.swift` | CPS 行削除 |
| `ContentView.swift` | `.finish` → FinishView 分岐追加 |

### UIKit

| ファイル | 変更内容 |
|---------|----------|
| `UIKit/GameTouchView.swift` | フェーズガード追加、コールバック変更、ParticleConfig新プロパティ適用 |

### リソース

| ファイル | 変更内容 |
|---------|----------|
| `Localizable.xcstrings` | `results.cps`, `results.max_touches` 削除、`finish.title` 追加 |

### テスト

| ファイル | 変更内容 |
|---------|----------|
| `TapBurstTests/ModelsTests.swift` | TitleDefinition 境界値テスト更新、CPSTier 閾値テスト更新 |
| `TapBurstTests/ScoreStoreTests.swift` | 変更なし |

---

## 実装タスクリスト

### Phase V2-A: モデル変更（TDD）+ ビルド追従

- [x] **V2-010** `GamePhase.swift` に `.finish` case を追加
  - テスト: 5つの case が存在することの確認
- [x] **V2-011** `GameSession.swift` を変更
  - `maxSimultaneousTouches` 削除
  - `lastValidTapTime: TimeInterval = 0` 追加
- [x] **V2-012** `ScoreResult.swift` を変更
  - `cps`, `maxSimultaneousTouches` 削除
- [x] **V2-013** `TitleDefinition.swift` の境界値を変更
  - テスト: 新境界値の全境界テスト
- [x] **V2-014** `CPSTier.swift` の閾値を変更（5/15 → 8/20）
  - テスト: 新閾値の境界テスト
- [x] **V2-015** `ParticleConfig.swift` に新プロパティ追加
  - velocity, velocityRange, scaleRange, scaleSpeed, color
  - テスト: 各 tier の値が仕様と一致すること
- [x] **V2-016** ビルド追従: モデル変更に伴う参照側の最小修正
  - `GameManager.endGame`: ScoreResult 生成から `cps`, `maxSimultaneousTouches` 削除
  - `GameManager.registerTaps`: `maxSimultaneousTouches` 更新削除
  - `GameManager.handleBackground`: `.finish` フェーズをホーム復帰対象に追加
  - `ResultsView`: CPS・同時タッチ行削除（→ V2-042 完了）
  - `ScorecardView`: CPS 行削除（→ V2-043 完了）
  - `ContentView`: `.finish` 分岐を安全なプレースホルダーとして追加（→ V2-041 完了、V2-040 で FinishView に差し替え予定）
- [x] **V2-017** `requirements.md` に技術的制約を追加
  - 専門家レビュー（docs/expert-reviews/2026-03-06-v2-game-mechanics-ux-review.md）の確定事項6件を技術的制約セクションに追記

### Phase V2-B: GameManager 変更

- [x] **V2-020** 1フレーム1カウントのスコア加算ロジック実装
  - タイムスタンプ比較方式（16.67ms 最小間隔）
  - `registerTaps` → `registerTap` にリファクタ
- [x] **V2-021** Finish フェーズの遷移ロジック実装
  - `endGame` → `phase = .finish` → 1.5秒後に `phase = .results`
  - Finish中のタッチ無効化
  - 参照先: `TapBurst/ViewModels/GameManager.swift` の `endGame(using:)`（現状 `phase = .results` を直接設定）
- [x] **V2-022** 2軸揺れ制御の実装
  - tapRateFactor × timeFactor（pow(t,3)）の乗算合成
  - sin波ベースの揺れパターン（X: 12.0 rad/s, Y: 15.6 rad/s）
  - `maxShakeAmplitude = 5.0`

### Phase V2-C: UIKit タッチ検出変更

- [x] **V2-030** `TouchDetectionView` のフェーズガード追加 + コールバック変更
  - `touchesBegan` で `.playing` 以外は return
  - コールバックを `onTaps(count, positions)` → `onTap(positions)` にリネーム（C-02 仕様準拠）
- [x] **V2-031** `TouchDetectionView` のパーティクル強化
  - ParticleConfig 新プロパティ（velocity, scaleRange, scaleSpeed, color）の適用

### Phase V2-D: View 変更

- [x] **V2-040** `FinishView.swift` 新規作成
  - 「FINISH!」+ スコアカウントアップアニメーション（0.85秒 easeOut、Timer.publishベース毎フレーム更新）
  - `allowsHitTesting(false)`
  - スコア表示に `lineLimit(1)` + `minimumScaleFactor(0.6)` 追加（横幅対策）
  - `#Preview(traits: .landscapeLeft)`
  - ContentView の `.finish` 分岐を `if let result` ガード付きで FinishView に差し替え
- [x] **V2-041** `ContentView.swift` に `.finish` 分岐追加（V2-016 で完了。現在はプレースホルダー、V2-040 で FinishView に差し替え）
- [x] **V2-042** `ResultsView.swift` から CPS・同時タッチ行を削除（V2-016 で完了）
  - [x] レイアウト調整（スコア・称号をより大きく表示 + 称号に `lineLimit(1)` / `minimumScaleFactor(0.5)` 追加）
- [x] **V2-043** `ScorecardView.swift` から CPS 行を削除（V2-016 で完了）
- [x] **V2-044** `Localizable.xcstrings` の更新
  - `results.cps`, `results.max_touches` 削除
  - `finish.title` 追加

### Phase V2-E: テスト更新

- [x] **V2-050** `ModelsTests.swift` のテスト更新
  - GamePhase: 5 case テスト
  - TitleDefinition: 新境界値テスト
  - CPSTier: 新閾値テスト
  - ParticleConfig: 新プロパティテスト

### 依存関係

```
V2-A (V2-010〜V2-017) ─── 先行必須 ───→ V2-B, V2-C, V2-D
  └ V2-016 でビルド追従として V2-041, V2-042, V2-043 を先行完了
V2-B (V2-020〜V2-022) ─── 先行必須 ───→ V2-D (V2-040)
V2-C (V2-030〜V2-031) ─── 並行可能 ───→ V2-B と並行可
V2-D (V2-040, V2-044) ─── 残タスク ───→ V2-B 完了後（V2-041〜V2-043 は完了済み）
V2-E (V2-050)         ─── V2-A と同時 ───→ TDD のためモデル変更と同時実施
```

---

## 変更履歴

| 日付 | バージョン | 変更内容 |
|------|----------|---------|
| 2026-03-06 | 0.1 | 初版作成（5つの変更仕様 + 実装タスク） |
