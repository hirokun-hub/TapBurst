# ランドスケープ結果画面レイアウト 専門家レビュー

> レビュー日: 2026-03-05
> レビュー対象: ResultsView.swift のランドスケープ対応レイアウト設計
> 回答者: 専門家O, 専門家A, 専門家G（3名）

---

## レビュー背景

ResultsView が VStack 縦一列レイアウト（必要高さ約509pt）で構成されており、iPhone SE 3rd gen のランドスケープ高さ（375pt）に収まらず下部が見切れる問題が発生。HStack 2カラムレイアウトへの変更案について専門家に意見を求めた。

---

## 全員一致の結論（信頼度 97%以上）

### 1. HStack 2カラムレイアウトはランドスケープ専用アプリにおけるベストプラクティスである

- 3名全員が「適切」「ベストプラクティス」と明言
- iPhone ランドスケープは縦方向が Compact で横方向に余裕があるため、情報（指標）とアクション（ボタン）を左右に分離するのは HIG のレイアウト適応原則に合致
- ScrollView による対応は不採用判断が正しい（ゲーム結果画面は一覧性が重要）
- フォントサイズ全体縮小も不採用判断が正しい（可読性低下のため）

**ソース:**
- [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

### 2. Safe Area の使い分け原則

3名全員が同じ原則を述べている:

| 対象 | 推奨 |
|---|---|
| 背景（グラデーション等） | `.ignoresSafeArea()` で画面端まで拡張 |
| 操作要素（ボタン・テキスト） | Safe Area 内に配置（SwiftUI デフォルト動作） |

- SwiftUI はデフォルトで Safe Area 内にコンテンツを配置する
- Dynamic Island 搭載機種のランドスケープ時 Safe Area も SwiftUI が自動処理するため、基本的に追加対応は不要

**ソース:**
- [Apple: ignoresSafeArea(_:edges:)](https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:))
- [Apple: Positioning content relative to the safe area](https://developer.apple.com/documentation/uikit/positioning-content-relative-to-the-safe-area)

### 3. 最小タップ領域 44pt × 44pt の確保

- Apple HIG はすべてのインタラクティブコントロールで最低 44pt × 44pt のタップ領域を要求
- 現在のボタン設計（28pt font + padding 14pt × 2 = 高さ約56pt）は要件を満たしている
- ボタン間スペーシング（14pt）も誤タップ防止に十分

**ソース:**
- [Apple HIG: Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)

### 4. ホームインジケータとの干渉回避

- Face ID 搭載機のランドスケープ時、ホームインジケータは画面下部に約21ptの Safe Area を要求
- Safe Area を尊重していれば基本的に問題なし
- 画面下部に主要ボタンを配置する場合は追加マージン（10〜16pt）が安全

**ソース:**
- [Apple: Positioning content relative to the safe area](https://developer.apple.com/documentation/uikit/positioning-content-relative-to-the-safe-area)

### 5. ランドスケープ両方向のサポート

- HIG はランドスケープのみのアプリでも landscapeLeft / landscapeRight の両方向をサポートすべきと明記
- `UISupportedInterfaceOrientations` に両方向が含まれていることを確認する必要がある

**ソース:**
- [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

---

## 専門家間で意見が分かれた点（参考情報）

### A. 左右カラムの垂直アラインメント

| 専門家 | 推奨 | 理由 |
|---|---|---|
| O | `.top` | 視線は上からスキャンされるため、先頭が揃う方が自然 |
| A | `.top` | 主要コンテンツは画面上部に配置すべき（HIG） |
| G | `.center` | 右下のデッドスペースを避け、画面全体の重心バランスを重視 |

→ 2対1で `.top` 推奨だが、デザイン上の判断による。

### B. ボタンカラムの幅制約方式

| 専門家 | 推奨 | 方式 |
|---|---|---|
| O | `idealWidth` + `min/max` | `minWidth: 200, idealWidth: 240, maxWidth: 280` |
| A | GeometryReader + 比率 | `geo.size.width * 0.38` |
| G | 固定 `maxWidth: 240` | シンプルで堅実 |

→ 3名とも異なるアプローチ。いずれも技術的に妥当。

### C. ViewThatFits による適応型レイアウト

- 専門家O のみが推奨。将来の要素追加・ローカライズ対応に有利
- 専門家A, G は言及なし
- ランドスケープ固定アプリでは縦に余裕があるケースが存在しないため、現時点では過剰設計の可能性がある

### D. `.padding(.horizontal, 24)` と `.safeAreaPadding()` の使い分け

- 専門家O, A: 現在の `.padding(.horizontal, 24)` は正しい。`.safeAreaPadding()` は代替として検討可
- 専門家G: Dynamic Island 機種では Safe Area（約59pt）+ padding（24pt）= 約83pt となり過剰な可能性を指摘。`.safeAreaPadding()` への切り替えを推奨
- ※ Safe Area の具体的な数値は機種・OS バージョンにより異なるため、実機検証で確認が必要

---

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-03-05 | 初版作成 |
