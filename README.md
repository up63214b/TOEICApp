# TOEIC 解答シートアプリ

SwiftUI で作られた iOS 向け TOEIC L&R テスト（200問）の解答シート・採点アプリです。
自分の回答と正解を入力して、パート別のスコアを確認できます。

---

## 機能一覧

- **解答シート作成** — TOEIC L&R 全200問（Part 1〜7）の解答シートを作成
- **回答入力** — A/B/C/D（Part 2のみA/B/C）をタップで入力、200問グリッドで一覧・ジャンプ
- **正解入力** — 回答と同じUIで正解データを入力
- **自動採点** — 全体・Listening/Reading・パート別の正解数と正解率を表示
- **学習履歴** — 採点済みシートを日付別に保存・閲覧、平均正解率の集計
- **タイマー** — 回答中の経過時間を計測

---

## ファイル構成

```
TOEICApp/TOEIC/
├── TOEICApp.swift                # アプリエントリーポイント
├── Models/
│   ├── AnswerSheet.swift         # データモデル（解答シート・パート定義・採点ロジック）
│   └── DataManager.swift         # UserDefaultsによる永続化（シングルトン）
├── ViewModels/
│   └── AnswerSheetViewModel.swift # 回答入力・タイマー・ステータス遷移の管理
└── Views/
    ├── ContentView.swift          # タブナビゲーション（ホーム/履歴/設定）
    ├── HomeView.swift             # 解答シート一覧
    ├── CreateSheetView.swift      # 新規シート作成フォーム
    ├── SheetDetailView.swift      # シート詳細・アクションボタン
    ├── AnswerInputView.swift      # 回答・正解の入力画面
    ├── QuestionGridView.swift     # 200問一覧グリッド（問題番号ジャンプ）
    ├── ScoringResultView.swift    # 採点結果画面
    ├── HistoryView.swift          # 採点済みシートの履歴
    └── SettingsView.swift         # 設定・データ管理
```

---

## セットアップ

### 必要な環境

- macOS 13.0 以上
- Xcode 15.0 以上

### 手順

```bash
# 1. リポジトリをクローン
git clone <repository-url>

# 2. Xcodeで開く
cd TOEICApp
open TOEICApp/TOEIC.xcodeproj
```

3. Xcode で **Signing & Capabilities** → チームを自分のApple IDに設定
4. シミュレーターまたは実機を選んで `Cmd + R` でビルド・実行

---

## 使用技術

| 技術 | 用途 |
|------|------|
| SwiftUI | UI フレームワーク |
| Combine | タイマー・リアクティブ更新 |
| UserDefaults | 解答シートデータの永続化 |
| MVVM | アーキテクチャパターン |

---

## ライセンス

MIT License

---

## 免責事項

TOEIC® is a registered trademark of ETS. This application is not endorsed or approved by ETS.
