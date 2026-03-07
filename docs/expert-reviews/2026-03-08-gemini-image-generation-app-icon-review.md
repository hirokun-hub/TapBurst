# Gemini画像生成（Imagen 3 / NanoBanana系）によるアプリアイコン・キービジュアル生成ベストプラクティス

> レビュー日: 2026-03-08
> 対象: TapBurst アプリアイコン（1024×1024px）およびキービジュアル生成
> 専門家: 3名（専門家O・専門家A・専門家G）の回答を統合・精査
> 信頼性基準: 3名中2名以上が一致、またはGoogle公式ドキュメントで裏付けられた情報のみ記載

---

## 1. モデルの位置づけ（NanoBanana2 vs NanoBanana Pro）

| 項目 | NanoBanana 2 | NanoBanana Pro |
|------|-------------|----------------|
| ベースモデル | Gemini 3.1 Flash Image | Gemini 3 Pro Image |
| 特性 | 高速・大量生成向き | 高品質・複雑な指示追従・推論ベース |
| 推奨用途 | 初期バリエーション大量出し | 最終仕上げ・複雑構図・微修正 |

**実務判断:**
- 初期の大量バリエーション出し → NanoBanana2
- 最終仕上げ・複雑指示 → NanoBanana Pro
- NanoBanana2で気に入った構図 → 「Redo with Pro」で品質向上（専門家G）

ソース:
- Google Blog: Nano Banana 2 announcement
- Google AI for Developers: Gemini API Image Generation — https://ai.google.dev/gemini-api/docs/image-generation

---

## 2. プロンプト構造テンプレート

### 2.1 基本原則

Google公式ガイドは **subject / context / style** を基本構造としている。重要な要素ほど先頭に配置する。

**推奨語順（3名共通）:**

```
[用途/媒体] → [主役モチーフ] → [構図] → [背景/文脈] → [色と光] → [スタイル] → [品質] → [禁止事項]
```

**推奨プロンプト長:**
- アイコン: 1〜3文、英語40〜90語
- キービジュアル: 2〜5文、英語80〜180語

ソース:
- Google Cloud: Prompt and image attribute guide（Vertex AI）
- Google Keyword Blog: "7 tips to get the most out of Nano Banana Pro" (2025-11-20) — https://blog.google/products/gemini/prompting-tips-nano-banana-pro/

### 2.2 スタイル指定

NanoBanana系はキーワード羅列（タグスープ）ではなく自然言語記述が効果的。以下のスタイル表現が安定:

- `polished 3D game icon` — ゲームアイコン向け立体感
- `premium digital illustration` — 高品質イラスト
- `clean stylized render` — クリーンな様式化レンダー
- `flat design with neon glow accents` — フラットデザイン＋ネオン

品質補強キーワード: `high-quality`, `stylized`, `detailed`, `crisp edges`, `4K`, `HDR`

### 2.3 ネガティブプロンプト

**Gemini APIのネイティブ画像生成（NanoBanana系）には独立したnegative promptパラメータは存在しない**（3名一致）。

対策:
- プロンプト本文末尾に自然言語で記述: `no text, no letters, no extra fingers, no busy background`
- Google公式はポジティブフレーミングを推奨: 「no cars」→「empty street」
- 両方を併用するのが実務上最も安定

注: Vertex AI の Imagen APIには独立した negative prompt パラメータがあるが、imagen-3.0-generate-002以降ではlegacy扱い（専門家O）。

---

## 3. アプリアイコン生成テクニック

### 3.1 構図・余白

以下のキーワードが歩留まりを上げる（3名共通）:

- `centered composition` — 中央配置
- `single dominant subject` / `single focal point` — 主役を1つに絞る
- `ample padding` / `ample negative space` — 十分な余白（角丸マスクで四隅が切れるため）
- `bold shapes, high contrast` — 大胆な形状、高コントラスト
- `clean background` / `solid dark background` — クリーンな背景
- `no tiny details` / `minimal micro-details` — 微細ディテール排除
- `readable at small size` / `must remain recognizable at very small size` — 小サイズ視認性

### 3.2 テキスト（文字）をアイコンに含めるべきか

**含めるべきではない**（3名一致）。

理由:
1. Apple Human Interface Guidelinesがアイコン内テキストを非推奨
2. 29×29pt等の極小表示では文字が潰れる
3. 日英2言語対応の場合、言語ごとにアイコンを変えるのは非効率
4. NanoBanana Proはテキスト描画能力が向上しているが、アイコンサイズでは無意味

プロンプトには明示的に `no text, no letters, no words, no typography` を含める。

### 3.3 手・指の描写

**リアルな手の描写はリスクが高い**（3名一致）。最新モデルでも指の本数・関節の構造的破綻が発生する。

推奨アプローチ（リスク低い順）:
1. 手を含めず、エネルギー/パーティクルの爆発のみで表現
2. `glowing hand silhouette` — 抽象化した手のシルエット
3. `abstract finger trails` — 抽象的な指の軌跡
4. 指先の接触点（衝撃波）のみ描写

### 3.4 アスペクト比

Gemini APIでサポートされるアスペクト比: 1:1, 3:2, 2:3, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9
NanoBanana2はさらに 1:4, 4:1, 1:8, 8:1 にも対応。

用途別推奨:
- アプリアイコン → **1:1**
- App Store横スクリーンショット・KV → 16:9
- SNS縦投稿 → 9:16

ソース:
- Google AI for Developers: Gemini API Image Generation — https://ai.google.dev/gemini-api/docs/image-generation

---

## 4. ゲーム世界観の視覚的翻訳キーワード

### 4.1 爆発的エネルギー
- `explosive energy`, `kinetic burst`, `impact shockwave`
- `energy eruption`, `radial light explosion`, `sparks flying outward`

### 4.2 指先のスピード感
- `rapid tapping motion`, `high-speed fingertip impact`
- `motion streaks`, `speed trails`, `staccato impact`

### 4.3 エスカレーションする興奮
- `escalating intensity`, `building momentum`, `rising pressure`
- `crescendo of energy`, `adrenaline surge`, `final-second climax`

### 4.4 ダーク＋ネオンのカラーパレット指定

色名＋形容詞の組み合わせで方向性をコントロールするのが最も安定:

```
deep navy and near-black base, electric cyan and vivid magenta neon glow,
warm orange impact highlights, high contrast, luminous particles,
subtle radial gradient
```

Hexコードは補助的に添える程度が無難（AIが厳密に従う保証はない）:
```
deep navy (#08111f), electric cyan (#00eaff), vivid magenta (#ff2bd6), hot orange (#ff8a00)
```

---

## 5. ウォーターマーク・商用利用

### SynthID
生成されたすべての画像に**不可視の電子透かし（SynthID）** が埋め込まれる（3名一致）。画質には影響せず、視覚的にも見えない。

### 商用利用
- Googleは生成コンテンツの所有権を主張しない
- 商用利用（App Storeアイコン含む）は認められている
- 利用者側で権利・商標・類似性・規約適合を確認する責任がある
- 既存IPや既存アプリアイコンに寄せすぎないよう注意

ソース:
- Google Gemini API Additional Terms
- Google AI for Developers: SynthID — https://ai.google.dev/gemini-api/docs/imagen

---

## 6. 反復改善ワークフロー

### シード値

- **Vertex AI Imagen API**: `seed` パラメータで決定論的生成が可能（`addWatermark=false` が必要）
- **NanoBanana2 / NanoBanana Pro（Gemini ネイティブ）**: シード値パラメータは提供されていない（専門家O・A一致）

### 推奨ワークフロー

1回のプロンプトで最終品質を得るのは非現実的。Google公式もiterative promptingを前提としている。

**アイコン（3〜5ラウンド）:**
1. NanoBanana2で8〜12案を大量生成（方向性探索）
2. 上位2〜3案のプロンプトを微修正して再生成
3. 最終候補をNanoBanana Proで仕上げ
4. 実機（iPhone SE〜Pro Max）で小サイズ表示して視認性確認

**A/Bテストの軸（毎回1軸のみ変更）:**
1. 主役モチーフ（指先 / 抽象爆発 / ネオンコア）
2. スタイル（3D / フラット / イラスト）
3. 色温度（寒色優勢 / マゼンタ強め / オレンジ強め）
4. 情報密度（簡潔 / 中程度 / 派手め）

---

## 7. TapBurst向けアイコンモチーフ候補

3名の専門家が共通して推奨したモチーフ方向性:

1. **タップ衝撃波型** — タップ瞬間の爆発・衝撃波を主役に（最も安全・推奨度最高）
2. **ネオンエネルギーコア型** — 発光するエネルギー核の爆発
3. **抽象スピード型** — 速度・インパクトを示す抽象的な発光シンボル

共通結論: アイコンは「ゲーム内容の説明」ではなく「一発認識される記号」として設計する。TapBurstの場合、その記号は「タップ衝撃のネオン爆発」が最適。

---

## 8. 汎用テンプレート

### テンプレートA: アイコン特化

```
A premium mobile game app icon of [single motif], centered composition,
one dominant subject, dark background, [color palette], [style],
high contrast, crisp silhouette, ample padding, must remain readable
at very small size, no text, no letters, no extra objects, no busy background
```

### テンプレートB: キービジュアル特化

```
A hero key visual for a fast-paced arcade tapping game, [main scene],
[camera/composition], [energy and motion description], [color palette],
[style], high-quality, stylized, cinematic, clean focal hierarchy,
no messy UI clutter
```

### テンプレートC: 反復改善用

```
Keep the same overall concept, but make it [more minimal / more energetic /
more premium / more readable at small size]. Strengthen [one attribute].
Reduce [one attribute]. Preserve the dark neon arcade mood.
```
