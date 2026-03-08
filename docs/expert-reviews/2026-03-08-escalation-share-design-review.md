# エスカレーション演出・シェア機能設計レビュー（2026-03-08）

3名の専門家（O, A, G）に対し、CPSTier多段階化、背景色CPS連動、揺れ改善、画像保存/シェア、プレイヤー名入力について技術的ベストプラクティスを確認した。以下は信頼性97%以上と判断した情報のみを記載する。

---

## 1. ピッチシフト段階設計（AVAudioUnitTimePitch）

### 1.1 AVAudioUnitTimePitch仕様
- `pitch` プロパティの単位は **cent**（100 cent = 半音、1200 cent = 1オクターブ）
- 指定可能範囲: -2400 〜 +2400 cent
- 内部実装は `kAudioUnitSubType_NewTimePitch`（スペクトラル方式）
- ソース: [Apple Developer Documentation - AVAudioUnitTimePitch](https://developer.apple.com/documentation/avfaudio/avaudiounittimepitch)

### 1.2 JND（最小知覚差異）
- 純音の弁別閾は実験環境で約10〜25 cent（周波数帯・音圧依存）
- **ゲーム中の実効JNDは25〜50 cent以上**に拡大する（短い効果音 + スピーカー再生 + 注意分散による）
- 3専門家とも「段階間の差は最低50 cent以上を確保すべき」で一致

### 1.3 推奨ピッチ範囲
- **実用上限: +700〜800 cent**（3専門家一致）
- +1200 cent（1オクターブ）以上は非推奨: アタック感の喪失、金属的アーティファクト、「チップマンク化」が顕在化
- 音質劣化はレイテンシ増加より先に問題になる
- バッファサイズ64サンプルの設定下でピッチ変更による追加レイテンシは実質なし（DSP処理はバッファ単位で完結）

### 1.4 段階設計の方針（3専門家の合意点）
- 低CPS帯は粗く、中〜高CPS帯（18 CPS前後）は密にする配分が適切
- 隣接段差は50〜120 centが実用帯
- 8段階程度が推奨（7〜10段階の範囲）

### 1.5 具体的な8段階ピッチテーブル（専門家O案を基準）

| Tier | CPS閾値 | pitch (cent) | 段階差 |
|------|---------|-------------|--------|
| T0 | 0〜4 | 0 | -- |
| T1 | 5〜7 | +60 | 60 |
| T2 | 8〜10 | +130 | 70 |
| T3 | 11〜14 | +220 | 90 |
| T4 | 15〜18 | +320 | 100 |
| T5 | 19〜22 | +430 | 110 |
| T6 | 23〜26 | +540 | 110 |
| T7 | 27〜30 | +680 | 140 |

注: 専門家Aは100 cent等間隔寄り、専門家Gは音楽的インターバル（完全4度=500, 完全5度=700）を推奨。ゲームSEには音楽理論より知覚の段階感を優先する専門家O案が最適と判断。

---

## 2. 背景色のCPS連動設計

### 2.1 責務分離の原則（3専門家一致）
- **TimeStage = 色相（hue）を主に制御**（青→紫→赤の世界観）
- **CPSTier = 彩度（saturation）と輝度（brightness）を主に制御**（くすんだ暗色→鮮やかな明色）
- 両軸で色相を大きく動かすと意味が衝突し、視覚的に破綻する

### 2.2 実装方式（推奨）
- TimeStageのベースグラデーション + CPSTierのオーバーレイ（opacity 0.0〜0.35）
- CPSTierの変化時のみ色を更新し、`.animation(.easeInOut(duration: 0.12〜0.3))` で遷移
- 毎フレームの色値直接更新は不要（tierが変わった時だけ更新）

### 2.3 Color補間API
- `Color.mix(with:by:in:)` は **iOS 18+** のAPI。iOS 17では使用不可
- iOS 17では `UIColor` に変換してRGBA手動補間、またはHSB空間での補間が必要
- RGB空間での補色補間は中間点でグレー化（彩度低下）するため、HSB空間を推奨
- ソース: [Apple Developer Documentation - Color.mix](https://developer.apple.com/documentation/swiftui/color/mix(with:by:in:))

### 2.4 パフォーマンス（iPhone SE 3rd gen）
- 単一LinearGradient + RadialGradient程度なら60fps維持は問題なし（3専門家一致）
- 危険なのは: 全画面blur、多数overlay、大量state更新によるViewツリー全体再評価
- `drawingGroup()` はシンプルなグラデーションには不要（逆にオフスクリーンレンダリングのコストが増える）
- 推奨: tier変化時のみアニメーション遷移、毎フレーム直接更新は避ける

### 2.5 色彩アンチパターン
- 高CPSで彩度と明度を同時に上げすぎると白飛びし、HUD（スコア・タイマー）の視認性が低下
- 背景色の最大輝度はHSBで0.85以下に制限し、ビネットオーバーレイを常時維持
- 毎段階で完全に別配色へジャンプすると興奮ではなく雑な点滅感になる

---

## 3. 画面揺れ（シェイクエフェクト）

### 3.1 知覚閾値の実務目安
- Apple公式の「何ptで揺れを知覚するか」の定義はない
- 実務的な目安（専門家O,A概ね一致）:
  - 0.5pt未満: ほぼ無意味
  - 1.5〜2.5pt: 揺れとして知覚可能
  - 3〜5pt: 明確に激しい
  - 6pt超: 人によっては不快
- **序盤の最低振幅は1.0〜1.5pt、終盤MAXは4〜5ptが適正**

### 3.2 timeFactor改善
- 現行 `pow(elapsed/10.0, 3.0)` は序盤が死ぬ（5秒時点で0.125）
- 推奨: **最低保証0.15〜0.18 + pow 1.6〜2.0**
  - 専門家O案: `0.18 + 0.82 * pow(elapsed/10.0, 1.6)`
  - 専門家A案: `0.15 + 0.85 * pow(elapsed/10.0, 2.0)`
- いずれも0秒時点で15〜18%を確保、中盤の立ち上がりを改善

### 3.3 Reduce Motion対応
- `UIAccessibility.isReduceMotionEnabled` を確認し、ONの場合は揺れ振幅を40〜60%に軽減すべき
- Apple HIGの要件として、過剰なモーションにはReduce Motion配慮が必要
- ソース: [Apple HIG - Motion](https://developer.apple.com/design/human-interface-guidelines/motion)

### 3.4 揺れ方式に関する専門家提案と採否
- 専門家O,A,Gともサイン波やPerlinノイズベースの滑らかな揺れを推奨
- **不採用**: 過去にサイン波方式を試行し、「揺れ」感が不足するため不採用とした経緯がある。フレームごとランダム方式を維持する

---

## 4. 画像保存・シェア機能

### 4.1 画像保存API（3専門家一致）
- **PHPhotoLibrary推奨**: `PHPhotoLibrary.shared().performChanges` + `PHAssetCreationRequest`
- async/awaitとの親和性が高く、エラーハンドリングが一元化される
- 保存後のPHAssetのlocalIdentifierが取得可能（将来拡張に有利）
- `UIImageWriteToSavedPhotosAlbum` は現時点で非推奨ではないが、Objective-Cベースの古いパターン
- ソース: [Apple Developer Documentation - PHPhotoLibrary](https://developer.apple.com/documentation/photokit/phphotolibrary)

### 4.2 必要な権限
- 保存のみ（読み取り不要）: `NSPhotoLibraryAddUsageDescription` をInfo.plistに追加
- 認可要求: `PHPhotoLibrary.requestAuthorization(for: .addOnly)`
- ソース: [Apple Developer Documentation - PHPhotoLibrary.authorizationStatus](https://developer.apple.com/documentation/photokit/phphotolibrary/authorizationstatus(for:))

### 4.3 権限未許可時のUX（3専門家一致）
- 最初から権限を聞かない（保存ボタンタップ時に初めて要求）
- 拒否された場合: アラートで設定アプリへ誘導（`UIApplication.openSettingsURLString`）
- 保存が拒否されてもシェア（Share Sheet）は引き続き利用可能にする

### 4.4 UIActivityViewControllerのactivityItems
- `UIImage` 直接渡し: シンプルだが、ヘッダー表示が空になることがある
- **一時ファイルURL推奨**（専門家A,G一致）: ファイル名制御可能（例: `TapBurst_180.png`）、AirDropでの表示が安定
- `UIActivityItemSource` + `LPLinkMetadata` でプレビュータイトル・サムネイルをカスタマイズ可能
- ソース: [Apple Developer Documentation - UIActivityViewController](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller)

---

## 5. プレイヤー名入力

### 5.1 入力タイミング（3専門家一致）
- **初回シェア時にシートで入力** が最も摩擦が少ない（ジャストインタイム方式）
- 一度入力した名前はUserDefaultsに保存し、次回以降はデフォルト値として自動使用
- 名前変更はシェア画面から編集可能にする
- カジュアルゲームでは設定画面への遷移は離脱を生む

### 5.2 文字数制限（3専門家一致）
- **表示上限: 12文字**（日本語・英数字混在を考慮）
- 内部保存は長くても良いが、スコアカード表示時は12文字で省略（`.lineLimit(1)` + `.truncationMode(.tail)`）

### 5.3 入力値のサニタイズ
- 先頭末尾の空白trim（`trimmingCharacters(in: .whitespacesAndNewlines)`）
- 改行・タブ・制御文字の除去
- 連続スペースの圧縮
- ゼロ幅文字（U+200B等）・RTLオーバーライド文字（U+202E等）のフィルタリング
- 絵文字は許可（ゲームのカジュアルさに合う）
- 空文字の場合はカードに名前欄を非表示

---

## 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-03-08 | 初版作成（専門家3名のレビュー結果を統合） |
