# 視覚エフェクト実装レビュー結果（2026-03-03）

3名のiOS開発専門家（専門家O・A・G）に視覚エフェクトのフレームワーク選定とアーキテクチャをレビュー依頼。
本ドキュメントには **3名中2名以上が一致し、かつ技術的に矛盾しない情報のみ** を記載する。

---

## 1. タップ位置パーティクル: CAEmitterLayer + CAEmitterCell（全員一致）

### 選定理由

- タッチ検出が UIViewRepresentable + UIKit UIView で確定済みのため、そのUIViewの `layer` に直接 `CAEmitterLayer` を sublayer として追加できる
- **座標変換が不要**（touchesBegan の `location(in:)` をそのまま `emitterPosition` に設定）
- パーティクルの生成・アニメーション・消滅は Core Animation のレンダリングサーバー（別プロセス）+ GPU で処理される。メインスレッドCPU負荷は `emitterPosition` 更新のみ（0.1〜0.5ms）
- iOS 17.0+ で非推奨なし。Core Animation の安定基盤API

### 不採用とした方式

| 方式 | 不採用理由 |
|------|-----------|
| SwiftUI Canvas + TimelineView | 毎フレームSwiftで全パーティクルの位置計算が必要でCPU負荷が最も高い。UIKit→SwiftUI座標変換と状態管理が複雑（専門家O・A一致） |
| SpriteKit (SKEmitterNode) | UIKit→SpriteKit座標変換が多段で最も複雑。SceneKitがiOS 26で非推奨となりSpriteKitも長期的に不透明。iOS 26.0でフレームレートリグレッション発生歴あり（専門家A） |

### パーティクルパラメータ制限値（iPhone SE 第3世代基準）

| パラメータ | 推奨値 |
|-----------|--------|
| 同時 emitter 数（最大） | 5（5指同時タッチ） |
| 1 emitter あたり birthRate | 30〜64/秒 |
| パーティクル lifetime | 0.2〜0.5秒 |
| 同時存在パーティクル数（理論最大） | 約75〜190個 |
| パーティクルテクスチャサイズ | 16×16〜32×32 pt |
| renderMode | `.additive`（発光感 + GPU効率） |

### CPS段階によるパラメータ変化

CPS軸エスカレーション（Appendix B）に応じて `scale` と `birthRate` を3セット用意する。

| CPS段階 | scale | birthRate目安 |
|---------|-------|-------------|
| 通常（0〜4） | 小 | 16〜30/秒 |
| 中（5〜14） | 中 | 30〜50/秒 |
| 最大（15+） | 大 | 50〜64/秒 |

### 実装パターン

- タップごとに CAEmitterLayer を生成し、短い lifetime（0.3〜0.5秒）を設定
- 生成直後に `birthRate` を 0 にして新規パーティクル生成を停止、既存パーティクルの寿命終了後に `removeFromSuperlayer()`
- 専門家Oの提案: emitter をプール再利用する方式も有効（毎回の生成・破棄を避けてレイヤーツリー更新コストを削減）

**ソース:**
- [CAEmitterLayer - Apple Developer](https://developer.apple.com/documentation/quartzcore/caemitterlayer)
- [CAEmitterCell - Apple Developer](https://developer.apple.com/documentation/quartzcore/caemittercell)
- [NSHipster: CAEmitterLayer](https://nshipster.com/caemitterlayer/)

---

## 2. 背景演出（時間軸エスカレーション）

### 専門家間の方針の違い

| 要素 | 専門家O | 専門家A・G |
|------|--------|-----------|
| 背景グラデーション | CAGradientLayer（UIKit） | SwiftUI LinearGradient + withAnimation |
| ビネット | CALayer + opacity | SwiftUI RadialGradient overlay |
| フラッシュ | CALayer + opacity | SwiftUI Color.white overlay |
| 画面振動 | CADisplayLink + transform | CADisplayLink + SwiftUI .offset（専門家A）/ KeyframeAnimator（専門家G） |

**共通する原則（全員一致）:**
- 背景演出はパーティクルシステムとは**統合せず独立したレイヤー**として実装する
- 重いフィルタ（ライブblur等）は使用しない（SE第3世代で性能低下リスク）
- ビネット・フラッシュは `.allowsHitTesting(false)` でタッチイベントを透過させる

### 演出要素別の推奨実装

| 演出要素 | 推奨方式 | 備考 |
|---------|---------|------|
| 背景色グラデーション遷移 | SwiftUI LinearGradient + withAnimation | 段階遷移時のみ状態更新。色補間は自動（専門家A・G一致） |
| ビネット効果 | SwiftUI RadialGradient（中心透明→周辺黒半透明）overlay | 静的オーバーレイの opacity 制御。パフォーマンス影響ほぼゼロ（専門家A・G一致） |
| 画面フラッシュ | SwiftUI Color.white overlay + opacity アニメーション | 終盤8〜10秒で0.5〜1秒間隔発火（専門家A・G一致） |
| 画面振動（視覚的揺れ） | CADisplayLink コールバック内で毎フレーム微小オフセット（±2〜4pt）を計算 | withAnimation だとスムーズすぎて振動感が出ない。フレーム単位の直接制御が適切（専門家O・A一致） |

---

## 3. レイヤー構成と描画順序（全員一致）

### 推奨構成（背面→前面）

```
ZStack {
  // Layer 1（最背面）: 背景演出 — SwiftUI
  BackgroundEffectView()          // グラデーション + ビネット
    .allowsHitTesting(false)

  // Layer 2: タッチ検出 + パーティクル — UIKit (UIViewRepresentable)
  GameTouchView()                 // UIView + CAEmitterLayer sublayers

  // Layer 3: フラッシュオーバーレイ — SwiftUI
  FlashOverlayView()
    .allowsHitTesting(false)

  // Layer 4（最前面）: UI表示 — SwiftUI
  GameHUDView()                   // スコア(72pt+) + 残り時間
    .allowsHitTesting(false)
}
```

### 設計の要点

- **タッチイベント配信**: GameTouchView（UIViewRepresentable）をZStackの中間層に配置。その上のSwiftUIビューはすべて `.allowsHitTesting(false)` を明示的に設定し、タッチイベントがUIKit層の touchesBegan に確実に到達するようにする
- **パーティクル配置**: CAEmitterLayer は GameTouchView（UIView）の sublayer として追加。タッチ検出と同一UIKit層に存在するため座標変換不要
- **スコア表示保護**: スコア（72pt+）は最前面のSwiftUI HUD層に配置し、パーティクルに遮られない。追加安全策として emissionRange/velocity を調整しスコア表示領域への飛散を抑制

### UIViewRepresentable のヒットテストに関する既知の問題

UIViewRepresentableにはSwiftUI側がヒットテスト設定を無視するケースが報告されている（Apple FB9818366）。上記のZStack構成（タッチ検出を中間層に配置 + 上層すべてに `.allowsHitTesting(false)`）により回避可能。

**ソース:**
- [Apple FB9818366: UIViewRepresentable hit-testing issue](https://openradar.appspot.com/FB9818366)

---

## 4. パフォーマンスバジェット配分

### 16ms フレームバジェット内の配分（iPhone SE 第3世代基準）

| 処理 | メインスレッド消費時間（目安） | 備考 |
|------|---------------------------|------|
| タッチ検出 + スコア加算 | ~0.5ms | touchesBegan は軽量 |
| CPS計算 | ~0.2ms | 配列操作、最大75要素 |
| タイマー更新 | ~0.1ms | CACurrentMediaTime() |
| SwiftUI状態更新 + 再描画 | ~2〜4ms | スコア表示、背景色変更 |
| **タップ位置エフェクト（CAEmitterLayer）** | **~0.3〜1.5ms** | emitterPosition更新。GPU側でパーティクル処理 |
| **背景演出** | **~0.5〜1ms** | SwiftUIアニメーション + 振動offset |
| 触覚フィードバック | ~0.2ms | 非同期ディスパッチ |
| オーディオ再生 | ~0.5ms | AVAudioEngine（別スレッド） |
| **合計** | **~4.3〜8ms** | |
| **余裕（バッファ）** | **~8〜12ms** | |

**視覚エフェクトの上限: CPU側で3〜5ms**（専門家O）/ **2〜3ms**（専門家A）

CAEmitterLayer方式はこのバジェット内に余裕を持って収まる（全員一致）。

---

## 5. iPhone SE 第3世代での実現可能性

### 60fps維持: 可能（全員一致）

- A15 Bionic は iPhone 13/13 Pro と同じ SoC
- ランドスケープ解像度 1334×750 は対応端末中最も低く、GPU描画負荷は最小
- CAEmitterLayer は数千パーティクルの同時描画でも60fps維持可能なエンジン
- 上記パラメータ制限値（同時最大190個程度）は余裕を持って処理可能

### 動的品質変更: 不要（全員一致）

- SE第3世代基準の統一設計を推奨
- 10秒間の短時間ゲームで、品質分岐の設計・テスト・バグ対応コストが割に合わない
- 将来の拡張に備え、パーティクルパラメータを定数ではなく設定構造体として切り出しておくことは有用（専門家A）

---

## SpriteKit に関する注意事項

- SceneKit が iOS 26（WWDC 2025）で正式に非推奨（deprecated）となった
- SpriteKit は正式には非推奨ではないが、長期間メジャーアップデートなし
- iOS 26.0 で SpriteKit にフレームレートリグレッション発生（iPhone 13でシンプルなシーンで約40fps。iOS 26.2 beta 3で修正）
- 新規プロジェクトでの SpriteKit 採用は推奨しにくい（専門家A）

**ソース:**
- [Apple Developer Forums: SpriteKit framerate drop on iOS 26](https://developer.apple.com/forums/thread/800952)
- [Paul Hudson: SceneKit deprecation](https://x.com/twostraws/status/1935675784150052921)

---

## レビュー参加者の信頼性評価

| 専門家 | 信頼性 | 備考 |
|--------|--------|------|
| 専門家O | 高 | 「プール再利用」「1フレーム1回間引き」等の実装レベルの提案が具体的。情報の限界を明示する姿勢が一貫。実在環境を正しく認識 |
| 専門家A | 高 | SpriteKitのリグレッション情報、UIViewRepresentableのヒットテスト既知問題（FB9818366）等、他の専門家が言及しなかった重要情報を提供。パフォーマンスバジェットの定量分析が最も精緻 |
| 専門家G | 中 | Xcode 26.3を再び「架空のバージョン」と誤認（前回レビューと同じ誤り）。技術的助言は概ね妥当だがパーティクル上限値（100〜200個/エフェクト）が他2名より大幅に多く、SE第3世代基準として楽観的すぎる可能性あり |
