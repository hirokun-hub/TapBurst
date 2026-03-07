# TapBurst アプリアイコン生成プロンプト集

> 作成日: 2026-03-08
> 対象モデル: NanoBanana2（初期バリエーション出し）→ NanoBanana Pro（最終仕上げ）
> ベストプラクティス参照: [docs/expert-reviews/2026-03-08-gemini-image-generation-app-icon-review.md](../expert-reviews/2026-03-08-gemini-image-generation-app-icon-review.md)
> 出力設定: アスペクト比 1:1、解像度 1K以上

---

## 使い方

### ワークフロー

1. NanoBanana2で5パターンそれぞれ2〜3枚ずつ生成（計10〜15枚）
2. 上位2〜3案に絞る
3. 下記「反復改善プロンプト」で微修正（1軸ずつ変更）
4. 最終候補をNanoBanana Proで再生成
5. 実機（iPhone SE 3rd gen〜Pro Max）でホーム画面に配置し小サイズ視認性を確認

### A/Bテスト時の変更軸（優先順）

1回につき1軸のみ変更すること。

1. 主役モチーフ（衝撃波 / ネオンコア / 抽象シンボル）
2. スタイル（3D / フラット / イラスト）
3. 色温度（シアン優勢 / マゼンタ強め / オレンジ強め）
4. 情報密度（ミニマル / 中程度 / 派手め）

---

## パターン1: タップ衝撃波型（3Dスタイル）

最も安全な王道パターン。タップ瞬間の爆発・衝撃波を主役に据える。

```
A premium mobile game app icon of a single glowing fingertip impact
burst radiating outward like a shockwave, centered composition, one
dominant subject, dark navy to black background with subtle radial
gradient, electric cyan and vivid magenta neon shockwave with warm
orange impact highlights, polished 3D game icon style, high contrast,
crisp silhouette, ample padding, must remain recognizable at very
small size, no text, no letters, no realistic hand, no extra objects,
no busy background
```

**意図:** ダークベースに映えるネオン衝撃波の一瞬を切り取る。3Dの立体感で存在感を出しつつ、シルエットはシンプルに保つ。

---

## パターン2: ネオンエネルギーコア型（デジタルイラスト）

中央に凝縮されたエネルギー核が爆発する瞬間。エスカレーションの「最大出力」を表現。

```
A mobile arcade game app icon of a luminous neon energy core
exploding outward with radiating particle trails, centered and
symmetrical composition, single focal point, deep black background,
vivid cyan and purple inner glow transitioning to hot orange and
magenta outer burst, premium digital illustration, stylized,
high-quality, large clear silhouette, ample safe margins, no text,
no typography, no tiny scattered particles near edges, no realistic
hand, no clutter
```

**意図:** 「バースト」の名にふさわしい爆発の瞬間。内側から外側へ色が遷移することで、エスカレーション（段階的激化）を1枚で表現。

---

## パターン3: 抽象スピードシンボル型（クリーンレンダー）

具体的なモチーフを排し、速度・インパクト・加速を示す抽象的な発光シンボル。

```
A bold app icon for a fast tapping arcade game, a single abstract
luminous burst symbol suggesting speed and repeated impact, dynamic
radial speed lines emanating from center, centered composition,
deep black and navy base, electric cyan core with hot orange and
magenta streaks, clean stylized render, minimal but powerful, crisp
edges, high contrast, readable at very small size, no text, no
numbers, no letters, no realistic fingers, no complex details
```

**意図:** 特定のモチーフに依存しない、純粋な「速度感」と「衝撃」の記号。最もミニマルで、小サイズでの視認性が最も高くなる可能性がある。

---

## パターン4: 連鎖パルス型（フラットデザイン）

複数のタップが連鎖的に波紋を生む様子を、フラットデザインで表現。

```
A square mobile game app icon in flat design style with neon glow
accents, concentric ripple rings expanding from a bright central
impact point suggesting rapid repeated tapping, centered composition,
solid dark background, layered rings in electric cyan and vivid
magenta with orange pulse accents, clean geometric shapes, bold
graphic design, high contrast, strong edge separation, ample padding,
must remain clear at thumbnail size, no text, no letters, no
gradients in background, no realistic elements, no hand
```

**意図:** フラットデザインの明快さと、同心円の波紋で「連打」を視覚化。幾何学的でモダンな印象。App Storeの他のカジュアルゲームと差別化しやすい。

---

## パターン5: 終盤クライマックス型（シネマティック）

ゲーム終盤（8〜10秒）の最大演出 ── 脈動・フラッシュ・振動が頂点に達した瞬間を凝縮。

```
A premium arcade game app icon showing escalating energy
concentrated into one explosive climax, a single brilliant starburst
with pulsating rings and motion streaks, centered and symmetrical,
dark background with deep purple to black gradient, inner cyan glow
bursting into outer magenta and orange flare, cinematic dramatic
lighting, polished game art, high-quality, stylized, bold silhouette,
ample margins, no text, no logo letters, no particles near edges,
no realistic hand, no extra subjects
```

**意図:** 「あと2秒」の興奮を1枚に閉じ込める。シネマティックなライティングで高級感を出しつつ、スターバーストの放射構図で視線を中央に集める。

---

## 反復改善プロンプト

気に入った生成結果をベースに微修正する際に使用する。

### 色調調整

```
Keep the same composition and subject, but shift the color palette
to [cooler tones with dominant cyan / warmer tones with dominant
orange / more magenta-purple emphasis]. Preserve the dark background
and neon glow aesthetic.
```

### 情報密度調整

```
Keep the same overall concept, but make it [more minimal with fewer
visual elements / more energetic with additional particle trails].
Preserve the dark neon arcade mood and centered composition.
```

### スタイル変更

```
Keep the same subject and color palette, but render it in [polished
3D style / clean flat vector style / premium digital illustration
style]. Maintain high contrast and small-size readability.
```

### 小サイズ視認性強化

```
Keep the same concept, but simplify the silhouette further for
better readability at very small sizes. Remove any fine details,
strengthen the main shape, increase contrast between subject and
background.
```
