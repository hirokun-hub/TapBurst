# 技術要件レビュー結果（2026-03-03）

3名のiOS開発専門家（専門家O・A・G）に要件定義書の技術的実現可能性をレビュー依頼。
本ドキュメントには **3名中2名以上が一致し、かつ公式ドキュメントと矛盾しない情報のみ** を記載する。

---

## 1. 開発環境とバージョン

### 要件定義書の更新が必要

- 要件定義書の「Xcode 16以降 + iOS 18 SDK」→ **「Xcode 26以降 + iOS 26 SDK」に更新が必要**（専門家O・A一致）
- AppleはWWDC 2025でバージョン番号を統一。iOS 18の次がiOS 26（数字が飛んだのは統一の結果）
- **2026-04-28以降、App StoreへのアプリはiOS 26 SDKでのビルドが必須**（専門家A）
- Deployment Target を iOS 17.0 に下げることは技術的に可能（全員一致）
- TapBurstの要件（SwiftUI、UserDefaults、Haptics、Audio等）はすべてiOS 17.0で利用可能な基本APIで実装可能

**ソース:**
- [Xcode Release Notes](https://developer.apple.com/documentation/xcode-release-notes/)
- [iOS & iPadOS Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/)

### SWIFT_VERSION 設定

- pbxprojの `SWIFT_VERSION = 5.0` は Swift言語モードを指す設定。Swift 6.x コンパイラは 5モード/6モードの両方をサポート
- **専門家間で意見が分かれた:**
  - 専門家O・G: Swift 6 に上げるべき（並行処理チェックを早期に有効化）
  - 専門家A: iOS開発未経験なら 5.0 のまま始めるべき（Swift 6モードはコンパイルエラーが大量発生しうる）
- Xcode 26ではSwift 6.2の「Approachable Concurrency」機能が導入済み。新規プロジェクトではデフォルトでMainActorが暗黙適用される（専門家A）

**結論:** 初学者は SWIFT_VERSION = 5.0 で開始し、アプリ完成後にSwift 6モードへ移行するのが現実的。

---

## 2. プロジェクト設定

### TARGETED_DEVICE_FAMILY

- **`"1"` に変更必須**（全員一致）
- `"1,2"` のままだとiPadでネイティブ動作が求められ、レイアウト・向き・クラッシュ等が審査対象になる
- `"1"` にすればiPad上ではiPhone互換モード（拡大表示）で動作し、iPad固有のUI調整が不要

---

## 3. マルチタッチ検出

### 推奨方式: UIViewRepresentable + カスタムUIView（全員一致）

- SwiftUIの標準ジェスチャ（`onTapGesture`等）では5本指同時タッチの要件を満たせない
- `UIViewRepresentable` でUIKitの `UIView` をラップし、`touchesBegan(_:with:)` を直接オーバーライド
- `touches` セットの `count` をそのまま同時タッチ数として加算（最大5）

### isMultipleTouchEnabled

- **デフォルト値は `false`**（全員一致）
- カスタムUIView内で `view.isMultipleTouchEnabled = true` を **明示的に設定必須**
- SwiftUIのView側ではなく、ブリッジしたUIView側で設定する

### 方式比較

| 方式 | レイテンシ | ドロップ率 | 実装複雑度 | 判定 |
|------|-----------|-----------|-----------|------|
| UIKit touchesBegan（推奨） | 数ms以下 | 最小（≒0%） | 中 | 採用 |
| SwiftUIジェスチャ | 中〜高（認識遅延） | 高（同時押しに弱い） | 低 | 不適合 |
| UIGestureRecognizerRepresentable（iOS 18+） | 低 | 低 | 低〜中 | iOS 17非対応 |

**ソース:**
- [UIView.isMultipleTouchEnabled](https://developer.apple.com/documentation/uikit/uiview/ismultipletouchenabled)
- [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)

---

## 4. ゲームタイマー

### 推奨構成: CADisplayLink + 単調増加クロック（全員一致）

- **画面更新:** CADisplayLink で60fps（またはProMotion端末で120fps）に同期
- **経過時間測定:** `CACurrentMediaTime()` / `mach_continuous_time()` / `ContinuousClock`（Swift 5.7+）等の単調増加クロックを使用
- **ゲーム終了判定:** CADisplayLinkの各フレームコールバック内で「経過時間 >= 10秒」を判定
- displayLinkの「フレーム回数」ではタイマーを管理しない（120Hz端末等でズレる）

### タイマー方式比較

| 方式 | 精度 | 適性 |
|------|------|------|
| CADisplayLink + monotonic clock（推奨） | フレーム精度（8.3〜16.6ms） | ゲーム用途に最適 |
| DispatchSourceTimer | ±0.2〜0.8ms（leeway前提） | タイマー精度は高いがUI同期がズレやすい |
| Timer (NSTimer) | ±50〜100ms | **不適合** |

**ソース:**
- [CADisplayLink](https://developer.apple.com/documentation/quartzcore/cadisplaylink)
- [CACurrentMediaTime](https://developer.apple.com/documentation/quartzcore/cacurrentmediatime())

---

## 5. リアルタイムCPS計算

### 推奨: タイムスタンプ配列（全員一致）

- `[TimeInterval]` 型の配列にタッチ発生時刻を追加
- 先頭から「現在時刻 - 1秒」より古い要素を除去
- 残った要素数 = リアルタイムCPS
- 最大75要素程度の操作は **1μs未満**。16msフレームバジェットへの影響は **無視可能（0.1%未満）**
- リングバッファ等の高度なデータ構造は不要

---

## 6. 触覚フィードバック（Haptics）

### UIImpactFeedbackGenerator の使用（全員一致）

- Apple公式ドキュメントに呼び出し頻度の明示的な上限値は **記載なし**
- 物理的制約: 高頻度（毎秒15回以上）では個別の振動が連続した振動に融合するか、システム側で間引かれる可能性あり
- 専門家Oの提案: **1フレームに1回までに間引く**（CADisplayLink周期でまとめる）のが安全

### prepare() のタイミング

- **ゲーム開始直前**（カウントダウン時）に `prepare()` を呼びTaptic Engineをウォームアップ
- フィードバック発生後に再度 `prepare()` を呼ぶとレイテンシ最小化（専門家A）

### 代替案: Core Haptics (CHHapticEngine)

- 高頻度シナリオではCHHapticEngineの方が精密なタイミング制御が可能（専門家A）
- 実装複雑度が上がるため、まずUIImpactFeedbackGeneratorで実装し、不足があれば移行を検討

**ソース:**
- [UIImpactFeedbackGenerator](https://developer.apple.com/documentation/uikit/uiimpactfeedbackgenerator)
- [Core Haptics](https://developer.apple.com/documentation/corehaptics)

---

## 7. サウンドエフェクト

### 推奨: AVAudioEngine + AVAudioPlayerNode + AVAudioUnitTimePitch（全員一致）

- 高頻度再生（毎秒15回以上）とリアルタイムピッチ変更の両立に最適
- レイテンシ: 約1.5ms（44.1kHz、バッファサイズ64サンプル時）（専門家A）
- 複数同時発音には複数のAVAudioPlayerNodeをプール管理

### フレームワーク比較

| フレームワーク | レイテンシ | ピッチ制御 | 判定 |
|--------------|-----------|-----------|------|
| AVAudioEngine（推奨） | 約1.5ms | AVAudioUnitTimePitchで可能 | 採用 |
| AudioToolbox/SystemSoundID | 約30〜50ms | 不可 | 不適合 |
| AVAudioPlayer | 約50〜100ms | 限定的 | 不適合 |

### サイレントモード対応（全員一致）

- iOSにサイレントスイッチ状態を検出する**公式APIは存在しない**
- **AVAudioSessionのカテゴリを `.ambient` に設定するだけで、NFR-15の要件を自動的に満たせる**
- `.ambient` カテゴリはサイレントモードON時にシステムが自動的にサウンドを無音にする
- アプリ側での条件分岐やスイッチ検出は不要

**ソース:**
- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AVAudioSession Category](https://developer.apple.com/documentation/avfaudio/avaudiosession/category)

---

## 8. UI制御

### ランドスケープ固定（全員一致）

- **Info.plist の `UISupportedInterfaceOrientations`** でランドスケープのみを指定
- Xcode: General → Deployment Info → Device Orientation で Landscape Left / Right のみチェック

### ステータスバー非表示（全員一致）

- SwiftUIの `.statusBarHidden(true)` をゲーム画面のViewに適用（iOS 17.0+で利用可能）

### 自動ロック無効化（全員一致）

- `UIApplication.shared.isIdleTimerDisabled = true` はSwiftUIでも引き続き使用可能
- `.onAppear` で `true`、`.onDisappear` で `false` に戻す

**ソース:**
- [UISupportedInterfaceOrientations](https://developer.apple.com/documentation/bundleresources/information_property_list/uisupportedinterfaceorientations)
- [statusBarHidden(_:)](https://developer.apple.com/documentation/swiftui/view/statusbarhidden(_:))

---

## 9. スコアカード画像生成

### 推奨: ImageRenderer（全員一致）

- SwiftUI ViewをImageRendererでオフスクリーン画像化（iOS 16+）
- iOS 17.0+環境での重大な既知制限なし
- `@MainActor` での実行が必要
- `proposedSize` でレンダリングサイズを明示指定（未指定だと出力がブレやすい）
- `AsyncImage` 等の非同期画像は使用不可（ローカルアセットを使用）

### QRコード生成（全員一致）

- `CIQRCodeGenerator`（CoreImage）で生成
- 出力画像は低解像度のため `CGAffineTransform(scaleX:y:)` で10〜20倍にスケールアップ

**ソース:**
- [ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [CIQRCodeGenerator](https://developer.apple.com/documentation/coreimage/ciqrcodegenerator)

---

## 10. データ永続化

### 推奨: UserDefaults（全員一致）

- Int型1値の保存に SwiftData は過剰。UserDefaults一択
- `synchronize()` は **非推奨（deprecated）であり不要**（全員一致）
- iOS 17.0+では、通常のプロセスキル（ユーザーによるスワイプ終了、システムによるバックグラウンド終了）でデータは保持される
- 「書いた直後の強制kill」で100%保証はないが、TapBurstの用途では実用上問題なし

**ソース:**
- [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)
- [UserDefaults.synchronize() - Deprecated](https://developer.apple.com/documentation/foundation/userdefaults/synchronize())

---

## iOS 17.0〜iOS 26.x で注意すべき非推奨API

| API | 状態 | 代替 |
|-----|------|------|
| `UserDefaults.synchronize()` | deprecated | 呼び出し不要（自動同期） |
| `Timer` でのゲームタイマー | 非推奨ではないが不適合 | CADisplayLink + monotonic clock |
| SwiftUI `onTapGesture` での高精度タッチ | 非推奨ではないが不適合 | UIViewRepresentable + touchesBegan |

---

## 専門家間で意見が分かれた事項

| 項目 | 専門家O | 専門家A | 専門家G | 採用方針 |
|------|--------|--------|--------|---------|
| SWIFT_VERSION | 6推奨 | 5.0維持（初心者向け） | 6推奨 | 5.0で開始、完成後に6移行 |
| 高頻度Haptics | 1フレーム1回に間引く | CHHapticEngine検討 | そのまま呼ぶ（物理限界は妥協） | まず間引き方式、不足ならCHHapticEngine |

---

## レビュー参加者の信頼性評価

| 専門家 | 信頼性 | 備考 |
|--------|--------|------|
| 専門家O | 高 | 慎重で情報ソースの限界を明示。実在環境(Xcode 26.3)を正しく認識 |
| 専門家A | 高 | 最も詳細。バージョン統一の経緯・App Store提出期限等の具体的日付を提供。実在環境を正しく認識 |
| 専門家G | 中 | Xcode 26.3を「タイポ」と誤認（実在を確認済み）。技術的助言自体は概ね妥当だがバージョン認識に重大な誤り |
