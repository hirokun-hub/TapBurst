# 称号システム10段階拡張レビュー (2026-03-08)

## レビュー概要

- 対象: 結果画面の称号（ランク）システムを7段階から10段階に拡張する設計
- 課題: プレイテストでスコアが150〜200に収束し、称号が固定化（主にマシンガンフィンガー）
- 専門家: 3名（O, A, G）による独立レビュー

## 確定事項（3名合意）

### 1. 10段階への拡張は妥当

- 7段階→10段階は過剰ではなく、最頻出帯の解像度を上げる「精密化」
- ゲームのランクシステムは8〜12段階が標準的（StarCraft II: 7段階、多くのMOBA/FPS: 8〜12段階）
- gamification feature richness研究では、低〜中程度の機能量が最も効果的

### 2. 最頻出帯（150〜200付近）を20〜30ポイント刻みで細分化

- Goal Gradient Effect（Hull, 1932; Kivetz et al., 2006）: 目標に近づくほど達成行動が加速する
- 20〜30刻みの根拠:
  - 10秒ゲームの1プレイ改善幅が10〜30タップ程度
  - 狭すぎる（10未満）と毎回称号がブレて希少性が失われる
  - 広すぎる（50以上）と変化が感じられず固定化する
  - 2〜3回の再挑戦で次の称号に届き得る幅

### 3. 分布方針: 低帯は粗く、中帯は密に、高帯は粗く

- 低スコア帯（0〜59程度）: 初心者の受け皿として広く保つ
- 最頻出帯（130〜220程度）: 20〜30刻みで3〜4段階に細分化
- 高スコア帯（270〜）: 到達困難な希少性を維持するため広く保つ

### 4. ネーミング原則

- 下位: ネガティブさを排除し「始まっている」「伸びている」前向きな表現
- 中位: 実力・勢い・成長を感じさせる表現
- 上位: 到達感・希少感・覚醒感のある表現
- 英語: 日本語の直訳を避け、短くパンチのある2〜3語（ゲーマー文化で通じる表現）

### 5. 追加UX推奨（全員一致）

- 「次の称号まであと○タップ」の明示が反復プレイ動機を最大化する（Goal Gradient Effect応用）
- ただし実装は称号テーブル変更とは別タスクとして扱う

## 参考知見（高信頼度）

### Goal Gradient Effect

目標に近づくほど人はその達成に向けた行動を加速させる。大きなゴールを小さな達成可能なステップに分割することで、各ステップの完了時に達成感が生まれ、次へ進むモチベーションが維持される。

- 出典: Hull, C. L. (1932). The goal-gradient hypothesis and maze learning.
- 出典: Kivetz, R., Urminsky, O., & Zheng, Y. (2006). The Goal-Gradient Hypothesis Resurrected. Journal of Marketing Research.
- 参考: LogRocket Blog "The goal gradient effect: Boosting user engagement" (2023)

### Near-Miss Effect

惜しい結果が次への挑戦意欲を掻き立てる現象。最頻出帯を細分化することで「あと少しで次の称号」という状況を意図的に多発させられる。

- 出典: Dixon et al., "Using Wordle to assess the effects of goal gradients and near-misses" (2024)

### Gamification Feature Richness

ゲーミフィケーション要素は低〜中程度の量が最も効果的。過剰な機能群は意図を弱めうる。10段階はこの「中程度の複雑さ」に収まる。

- 出典: Sun et al., "Is more always better? An S-shaped impact of gamification feature richness on exercise adherence intention" (2025)

### レベルシステム3フェーズ設計

Onboarding（素早くレベルアップ）→ Scaffolding（細かいマイルストーン）→ Endgame（到達困難な目標）の3フェーズで設計すべき。

- 出典: Yu-kai Chou "Leveling System (GT#85) and League Rank (GT#101)" - yukaichou.com

### Skill-Challenge Balance

楽しさや継続意図にはskill-challenge balanceやcompetence感が強く関わる。カジュアル層には「自分は前進できている」と感じさせることが特に重要。

- 出典: Tyack et al., "Self-Determination Theory and HCI Games Research" (2024)
- 出典: Schmierbach et al., "No one likes to lose: The effect of game difficulty on competency, flow, and enjoyment" (2014)
- 出典: Larche et al., "The relationship between the skill-challenge balance, game expertise, flow, and the urge to keep playing complex mobile games" (2020)

### プレイヤーリテンション

保持率の高いゲームはprogression curveを能動的に管理し、大目標の間にintermediate / chunked goalsを置いて勢いを維持している。目標はout of reachに感じさせてはいけない。

- 出典: Google Play Apps & Games Team, "Understanding Games that Retain" / "Games that retain" (2022)

## 運用指針

称号テーブルは静的に完璧な帯域を先に決めるより、実測分布ベースで微調整するのが最も効果的。

1. まず10段階テーブルを仮採用
2. 100〜300点のヒストグラムを500〜1000プレイ分ほど取得
3. 各称号の出現率が極端に偏る帯を再調整
4. 目安: 最頻出称号が全体の18〜22%を超えるならさらに分割、5%未満なら統合を検討
