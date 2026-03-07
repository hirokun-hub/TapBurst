# HomeView UI/UX 改善レビュー (2026-03-08)

## レビュー概要

タイトル画面（HomeView）への「今日のベスト」表示追加、履歴一括削除機能、デザイン改善について3名の専門家にレビューを依頼。

## 確定事項（信頼性97%以上）

### 1. レイアウト: ランドスケープでの2カラム構成

3名全員が**左右分割（HStack系）レイアウトを推奨**。

- ランドスケープiPhoneの横幅は約800〜932pt。VStack中央揃えでは左右に大量のデッドスペースが生じる
- 左にブランド・スコア情報、右にSTART（主アクション）を配置する2カラム構成が適切
- 比率は左40〜55%/右45〜60%。STARTボタン側をやや広くとる
- 実装: `HStack` ベースで `GeometryReader` またはflexibleな比率で iPhone SE〜Pro Maxの幅差を吸収

参考: Apple HIG - Layout（横長画面の空間活用）、既存の技術的制約「ランドスケープUIの縦幅制約」（requirements.md）と整合

### 2. 破壊的アクションの確認UI

- **`.confirmationDialog` を使用する**（`.actionSheet` は iOS 15+ で非推奨、`confirmationDialog` がその後継）
- `.alert` はエラー通知・情報提示用途。ユーザー主導の破壊的操作確認には `confirmationDialog` が意味論的に適切
- `confirmationDialog` は画面下部からスライドするシートとして表示され、Cancel ボタンがデフォルトで含まれる
- 破壊的アクションのボタンには `Button("...", role: .destructive)` を付与（iOS が自動的にテキストを赤色表示）
- 確認文には**何が消えるかを具体的に記述**する

ソース:
- [Apple Developer Documentation: confirmationDialog](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:)-46zbb)
- [Apple HIG: Action sheets](https://developer.apple.com/design/human-interface-guidelines/action-sheets)

### 3. 「今日のベスト」の主従表現

- フォントサイズ差だけでは不十分。**サイズ + コントラスト（明度差）+ ウェイト差**の複合で差別化する
- 歴代ベスト（主）: 大きいフォント（48〜64pt）、heavy/blackウェイト、高コントラスト
- 今日のベスト（従）: 小さめフォント（24〜30pt）、semibold程度、`.secondary` や opacity で控えめに

### 4. 未プレイ時の表示

- **「---」を推奨**（3名一致）
- 「0」は「0回タップした結果」と誤解されるリスクがある
- 非表示は、初プレイ後にレイアウトがジャンプし、存在自体を学習できない

### 5. iOS 17+ で使える効果的な演出技法

| 技法 | 対応OS | 効果 | 備考 |
|------|--------|------|------|
| テキストグラデーション（`.foregroundStyle(LinearGradient(...))`） | iOS 15+ | タイトルの印象を1行で大幅改善 | 派手すぎると安っぽくなる。2〜3色が適切 |
| STARTボタンのパルスアニメーション（scaleEffect 1.0↔1.05） | iOS 15+ | CTA誘導効果が高い。ゲームタイトル画面の定番 | 振幅は控えめに（1.03〜1.05倍） |
| `.phaseAnimator`（フェーズベースアニメーション） | iOS 17+ | パルス等を宣言的に記述可能 | `repeatForever` アニメーションの代替 |
| `.symbolEffect(.pulse)` / `.symbolEffect(.bounce)` | iOS 17+ | SF Symbolsに軽いアニメーション付与 | 装飾ではなく意味づけされた動きに限定 |
| Material（`.ultraThinMaterial` 等） | iOS 15+ | 背景と前景の視覚的分離、階層化 | スコア表示パネルに適用すると上品に整理できる |
| `.shadow()` 重ねがけ | iOS 13+ | ネオングロー的効果 | 色付きshadow 2〜3枚でゲームらしい印象 |

**使用不可・非推奨:**
| 技法 | 理由 |
|------|------|
| `MeshGradient` | iOS 18+ 限定。プロジェクトの最低対応は iOS 17.0 |
| `.visualEffect` | iOS 17で導入されたがスクロール連動用途が主。タイトル画面の静的演出には過剰 |
| Metal `ShaderLibrary` | iOS 17で可能だがMVPフェーズには複雑すぎる |

ソース:
- [Apple Developer Documentation: foregroundStyle](https://developer.apple.com/documentation/swiftui/view/foregroundstyle(_:))
- [Apple Developer Documentation: symbolEffect](https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:value:))
- [Apple Developer Documentation: phaseAnimator](https://developer.apple.com/documentation/swiftui/view/phaseanimator(_:content:animation:))
- [Apple Developer Documentation: Material](https://developer.apple.com/documentation/swiftui/material)

### 6. リセットボタンの配置

- ホーム画面に配置するなら**視覚的優先度をかなり下げる**（主役はSTART）
- アイコンは `arrow.counterclockwise`（リセット/やり直し感） or `trash`（削除感）
- スコア表示エリアに紐づけて配置すると意味的に通りやすい
- 設定画面に逃がす案、ベスト表示の長押しで補助メニュー案も有力

### 7. 追加提案（複数専門家が言及）

- **「あと X で歴代更新」の差分表示**: 歴代ベストと今日のベストの差を小さく出すと、数値が行動理由に変わる（今日のベストが0の場合は非表示）
- **STARTボタンへのハプティクス**: `.sensoryFeedback(.impact, trigger: ...)` (iOS 17+) でゲーム開始の「重み」を演出
- **キャッチコピー**: STARTボタン近くに「10秒、全力。」等の短い補助テキストを薄い色で配置（ルール説明不要で意図が伝わる）

## 不採用・保留事項

| 提案 | 理由 |
|------|------|
| 「画面のどこをタップしてもスタート」 | カウントダウン中の誤タップ防止設計と矛盾。明示的STARTボタンの方がゲームフローが明確 |
| 「前回のスコア」表示 | 情報過多リスク。MVP段階では今日のベストで十分。将来的な拡張候補 |
| SwiftDataへの移行 | 現時点では Int 2値（歴代ベスト + 今日のベスト）の保存で UserDefaults が適切。スコア履歴・グラフ機能が必要になった時点で検討 |
