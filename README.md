# 📱 TOEIC英語学習アプリ

SwiftUI で作られた iOS 向け TOEIC 対策問題集アプリです。  
Part 5（短文穴埋め）・Part 6（長文穴埋め）・Part 7（読解）に対応しています。

---

## 📸 スクリーンショット

<!-- 実機またはシミュレーターでのスクリーンショットをここに追加してください -->
| ホーム | 問題画面 | 結果画面 |
|--------|---------|---------|
| (スクリーンショット追加予定) | (スクリーンショット追加予定) | (スクリーンショット追加予定) |

---

## ✨ 機能一覧

- **問題集選択** — Part別・難易度別に問題セットを選んで学習
- **4択回答** — タップで即座に正誤判定（緑/赤の色で可視化）
- **解説表示** — 各問題の日本語解説をワンタップで確認
- **結果画面** — スコアをアニメーション付きのサークルで表示
- **学習履歴** — 過去の学習記録を日付別に保存・閲覧
- **復習モード** — 間違えた問題だけをまとめて再出題
- **学習タイマー** — 問題ごとの経過時間を計測

---

## 🗂️ ファイル構成

```
TOEICApp/
├── TOEICAppApp.swift          # アプリエントリーポイント
├── Models/
│   ├── Question.swift         # データモデル（問題・回答・履歴）
│   ├── SampleData.swift       # 問題データ（Part5: 18問、Part7: 3問）
│   └── DataManager.swift      # UserDefaultsによる永続化
├── ViewModels/
│   └── QuizViewModel.swift    # クイズ進行・タイマー・スコア計算
└── Views/
    ├── ContentView.swift       # タブナビゲーション
    ├── HomeView.swift          # ホーム・問題集一覧
    ├── QuizContainerView.swift # 問題表示・回答・解説
    ├── ResultView.swift        # 結果画面
    ├── ReviewView.swift        # 復習画面
    ├── HistoryView.swift       # 学習履歴
    └── SettingsView.swift      # 設定
```

---

## 🚀 セットアップ（ローカル実行手順）

### 必要な環境

- macOS 13.0 以上
- Xcode 15.0 以上
- iOS 16.0 以上（ターゲット端末）

### 手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/あなたのユーザー名/TOEICApp.git

# 2. ディレクトリに移動
cd TOEICApp

# 3. Xcodeで開く
open TOEICApp.xcodeproj
```

4. Xcode で **Signing & Capabilities** → チームを自分のApple IDに設定
5. シミュレーターまたは実機を選んで `⌘ + R` でビルド・実行

---

## 🔧 問題の追加方法

`TOEICApp/Models/SampleData.swift` を編集します：

```swift
Question(
    text: "The _____ of the new product exceeded expectations.",
    options: ["launch", "launched", "launching", "launches"],
    correctAnswerIndex: 0,   // A=0, B=1, C=2, D=3
    explanation: "ここに解説を書きます。",
    part: .part5
)
```

---

## 🛠️ 使用技術

| 技術 | 用途 |
|------|------|
| SwiftUI | UI フレームワーク |
| Combine | リアクティブプログラミング |
| UserDefaults | 学習履歴・復習データの永続化 |
| MVVM | アーキテクチャパターン |

---

## 📋 今後の予定（TODO）

- [ ] 音声問題対応（Part 1〜4）
- [ ] 問題数の大幅追加
- [ ] 学習グラフ（週次・月次の統計）
- [ ] ウィジェット（今日の1問）
- [ ] iCloud 同期

---

## ⚖️ ライセンス

MIT License

---

## ⚠️ 免責事項

TOEIC® is a registered trademark of ETS. This application is not endorsed or approved by ETS.
