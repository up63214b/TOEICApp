# TOEICApp v3.0 要件定義書

**作成日**: 2026-02-19
**対象**: TOEICApp iOS アプリ
**ステータス**: ドラフト

---

## 1. 背景・目的

現在の v2.0 は「解答シート作成 → 回答入力 → 正解入力 → 採点 → 結果確認」の基本フローが完成している。
v3.0 では以下の3点を改善し、学習効率と操作性を向上させる。

1. **入力順序の自由化** — 正解を先に入力してから回答する使い方に対応
2. **間違い一覧・復習機能** — 採点後に間違えた問題を一覧で確認
3. **スワイプ問題移動** — 左右スワイプで問題を素早く移動

---

## 2. 機能一覧

| ID | 機能名 | 優先度 |
|----|--------|--------|
| F1 | 入力順序の自由化 | 高 |
| F2 | 間違い一覧・復習機能 | 高 |
| F3 | スワイプ問題移動 | 中 |

---

## 3. 機能詳細

### F1: 入力順序の自由化

#### 3.1.1 概要

シート作成後に「回答から始める」「正解から始める」を選択できるようにする。
現在は `answering → answered → scoring → scored` の一方向フローだが、
正解を先に入力してから回答するフローも追加する。

#### 3.1.2 ユーザーストーリー

- ユーザーとして、模擬試験の正解データを先に入力しておき、後から自分の回答を入力して採点したい
- ユーザーとして、シート作成時にどちらから入力するか選びたい
- ユーザーとして、正解入力中に回答入力に切り替えたい（逆も同様）

#### 3.1.3 画面・フロー変更

**CreateSheetView の変更:**

シート作成フォームに「入力開始モード」の選択肢を追加する。

```
┌─────────────────────────────┐
│ 新しい解答シート              │
│                             │
│ タイトル: [TOEIC 2026/02/19] │
│                             │
│ 最初に入力するもの:           │
│  ● 問題回答から始める（デフォルト） │
│  ○ 正解入力から始める             │
│                             │
│       [作成]                 │
└─────────────────────────────┘
```

**SheetStatus の変更:**

新しいステータスを追加する。

```
現在:
  answering → answered → scoring → scored

変更後:
  answering     → answered     → scoring → scored  （回答先行パターン）
  correctInput  → correctReady → answering → answered → scored  （正解先行パターン）
```

| ステータス | 意味 | 備考 |
|-----------|------|------|
| `answering` | 回答入力中 | 既存（変更なし） |
| `answered` | 回答完了 | 既存（変更なし） |
| `scoring` | 正解入力中（回答先行パターン） | 既存（変更なし） |
| `scored` | 採点完了 | 既存（変更なし） |
| `correctInput` | **新規**: 正解入力中（正解先行パターン） |  |
| `correctReady` | **新規**: 正解入力完了、回答待ち |  |

**SheetDetailView のボタン変更:**

| ステータス | 主ボタン | 副ボタン |
|-----------|---------|---------|
| `answering` | 回答を続ける | — |
| `answered` | 正解を入力する | 回答を修正する |
| `scoring` | 正解入力を続ける | 採点する（全問入力時） |
| `scored` | 採点結果を見る | — |
| `correctInput` | **正解入力を続ける** | — |
| `correctReady` | **回答を入力する** | **正解を修正する** |

**AnswerInputView の変更:**

- `correctInput` ステータスでは正解入力 UI を表示（タイマーなし）
- `correctReady` → 「回答を入力する」で `answering` に遷移してタイマー開始

**ViewModel の変更:**

以下のメソッドを追加する:

```swift
/// 正解入力を完了する（正解先行パターン）
func finishCorrectInput() {
    sheet.status = .correctReady
    save()
}

/// 正解先行パターンから回答入力を開始する
func startAnsweringAfterCorrect() {
    inputMode = .answer
    sheet.status = .answering
    currentQuestion = 1
    moveToFirstUnanswered()
    save()
}
```

**採点ロジックの変更:**

正解先行パターンでは、回答完了時に自動的に `scored` にする。
（回答と正解の両方が揃っているため、別途正解入力ステップが不要）

```swift
/// 回答完了にする（正解先行パターンの場合は自動採点）
func finishAnswering() {
    stopTimer()
    if sheet.isFullyCorrectAnswered {
        // 正解先行パターン: 正解が既に全問入力済みなら自動採点
        sheet.status = .scored
    } else {
        sheet.status = .answered
    }
    save()
}
```

#### 3.1.4 データモデル変更

**AnswerSheet:**

```swift
struct AnswerSheet: Identifiable, Codable {
    // 既存フィールド（変更なし）
    ...

    // 新規フィールド: 作成時にどちらから入力を始めたか記録
    var inputOrder: InputOrder  // .answerFirst or .correctFirst
}

enum InputOrder: String, Codable {
    case answerFirst   // 回答先行（従来の動作）
    case correctFirst  // 正解先行
}
```

**SheetStatus:**

```swift
enum SheetStatus: String, Codable {
    case answering      // 回答入力中
    case answered       // 回答完了
    case scoring        // 正解入力中（回答先行）
    case scored         // 採点完了
    case correctInput   // 正解入力中（正解先行）  ← 新規
    case correctReady   // 正解入力完了、回答待ち  ← 新規
}
```

#### 3.1.5 既存データとの互換性

- 既存シートには `inputOrder` が存在しない → デコード時にデフォルト `.answerFirst` を設定
- 既存の `answering`/`answered`/`scoring`/`scored` ステータスは変更なし

---

### F2: 間違い一覧・復習機能

#### 3.2.1 概要

採点完了後のシートに対して、間違えた問題の一覧を確認できる画面を追加する。
各問題について「自分の回答」「正解」「パート情報」を表示する。

#### 3.2.2 ユーザーストーリー

- ユーザーとして、どの問題を間違えたか一覧で確認したい
- ユーザーとして、パート別にフィルターして弱点を把握したい
- ユーザーとして、間違えた問題数をひと目で確認したい

#### 3.2.3 新規画面: WrongAnswersView

**アクセス方法:**
- ScoringResultView 内に「間違えた問題を見る」ボタンを配置
- SheetDetailView（scored 状態）にも直接アクセスボタンを配置

**レイアウト:**

```
┌─────────────────────────────────┐
│ ← 間違えた問題 (42問)            │
├─────────────────────────────────┤
│ フィルター: [全て] [L] [R]       │
│   [Part1][Part2]...[Part7]      │
├─────────────────────────────────┤
│                                 │
│ Part 1 - 写真描写問題            │
│ ┌─────────────────────────────┐ │
│ │ Q3   あなた: B  正解: D      │ │
│ │ Q5   あなた: A  正解: C      │ │
│ └─────────────────────────────┘ │
│                                 │
│ Part 3 - 会話問題               │
│ ┌─────────────────────────────┐ │
│ │ Q35  あなた: C  正解: A      │ │
│ │ Q38  あなた: --  正解: B     │ │  ← 未回答
│ │ ...                          │ │
│ └─────────────────────────────┘ │
│                                 │
│ (全パート分を表示)               │
└─────────────────────────────────┘
```

**フィルター機能:**

| フィルター | 表示内容 |
|-----------|---------|
| 全て | 全パートの間違い |
| L（リスニング） | Part 1〜4 の間違い |
| R（リーディング） | Part 5〜7 の間違い |
| Part N | 特定パートの間違いのみ |

#### 3.2.4 データモデル変更

データモデルの変更は不要。既存の `userAnswers` と `correctAnswers` から間違い情報を算出する。

**AnswerSheet に算出プロパティを追加:**

```swift
/// 間違えた問題の一覧（問題番号、ユーザー回答、正解をまとめた配列）
var wrongAnswers: [WrongAnswer] {
    // userAnswers と correctAnswers を比較して不一致を返す
}
```

**新規構造体:**

```swift
struct WrongAnswer: Identifiable {
    let questionNumber: Int
    let userAnswer: String?    // nil = 未回答
    let correctAnswer: String
    let part: TOEICPart

    var id: Int { questionNumber }
}
```

---

### F3: スワイプ問題移動

#### 3.3.1 概要

AnswerInputView で左右スワイプジェスチャーにより前後の問題へ移動できるようにする。
既存のボタン操作に加え、直感的な操作を提供する。

#### 3.3.2 ユーザーストーリー

- ユーザーとして、スワイプで素早く次の問題に移動したい
- ユーザーとして、戻って回答を確認・修正するときもスワイプで戻りたい

#### 3.3.3 実装仕様

**ジェスチャー:**

| ジェスチャー | 動作 |
|-------------|------|
| 左スワイプ | 次の問題へ（goNext） |
| 右スワイプ | 前の問題へ（goPrevious） |

**実装方法:**

AnswerInputView の問題表示エリアに `.gesture(DragGesture())` を追加する。

```swift
.gesture(
    DragGesture(minimumDistance: 50)
        .onEnded { value in
            if value.translation.width < -50 {
                viewModel.goNext()      // 左スワイプ → 次へ
            } else if value.translation.width > 50 {
                viewModel.goPrevious()  // 右スワイプ → 前へ
            }
        }
)
```

**制約:**
- Q1 で右スワイプ → 何もしない（既存の goPrevious の動作と同じ）
- Q200 で左スワイプ → 何もしない（既存の goNext の動作と同じ）
- 選択肢ボタンのタップと干渉しないよう、`minimumDistance: 50` を設定
- スワイプ時に軽いアニメーション（`.transition` または `withAnimation`）を付ける

#### 3.3.4 データモデル変更

なし。ViewModel の既存メソッド（goNext / goPrevious）をそのまま利用する。

---

## 4. 変更対象ファイル一覧

| ファイル | F1 | F2 | F3 | 変更内容 |
|---------|:--:|:--:|:--:|---------|
| `Models/AnswerSheet.swift` | ○ | ○ | - | InputOrder追加、SheetStatus追加、wrongAnswersプロパティ追加 |
| `ViewModels/AnswerSheetViewModel.swift` | ○ | - | - | 正解先行フロー用メソッド追加、finishAnswering変更 |
| `Views/CreateSheetView.swift` | ○ | - | - | 入力開始モード選択UI追加 |
| `Views/SheetDetailView.swift` | ○ | ○ | - | 新ステータス用ボタン追加、間違い一覧ボタン追加 |
| `Views/AnswerInputView.swift` | ○ | - | ○ | 正解先行モード対応、スワイプジェスチャー追加 |
| `Views/ScoringResultView.swift` | - | ○ | - | 間違い一覧ボタン追加 |
| `Views/WrongAnswersView.swift` | - | ○ | - | **新規作成**: 間違い一覧画面 |
| `Views/HomeView.swift` | ○ | - | - | 新ステータスの表示対応 |

---

## 5. 実装順序

```
Step 1: F1 - データモデル変更（InputOrder, SheetStatus追加）
    ↓
Step 2: F1 - ViewModel 変更（正解先行フロー用メソッド）
    ↓
Step 3: F1 - View 変更（CreateSheetView, SheetDetailView, AnswerInputView, HomeView）
    ↓
Step 4: F2 - WrongAnswer モデル追加 + wrongAnswers プロパティ
    ↓
Step 5: F2 - WrongAnswersView 新規作成
    ↓
Step 6: F2 - ScoringResultView, SheetDetailView にボタン追加
    ↓
Step 7: F3 - AnswerInputView にスワイプジェスチャー追加
    ↓
Step 8: 全体テスト・動作確認
```

---

## 6. 非機能要件

- **後方互換性**: 既存の保存データ（UserDefaults）が壊れないこと。新フィールドにはデフォルト値を設定する
- **パフォーマンス**: 200問分の間違い一覧表示が遅延なく描画されること（LazyVStack 使用）
- **アクセシビリティ**: スワイプ操作ができない場合でも、既存のボタンで全操作が可能であること

---

## 7. 対象外（今回のスコープ外）

- TOEIC換算スコア（5〜495点）の推定計算
- パート別推移グラフ
- 学習カレンダー・連続学習日数
- CSV エクスポート
- タイマー強化（制限時間設定）
- iCloud 同期