# CLAUDE.md - TOEICApp

## Memory Files（セッション記憶システム）

**セッション開始時に必ず以下の順番で読むこと：**

1. `../CLAUDE.md` -- ワークスペース共通ルール
2. `../lessons.md` -- 全プロジェクト共通の教訓ログ
3. `CLAUDE.md`（このファイル）-- プロジェクト固有のルール
4. `progress.txt` -- プロジェクトの進捗メモリ
5. `lessons.md` -- プロジェクト固有の教訓ログ

## プロジェクト概要

TOEIC L&R テスト対策用のiOSアプリ。
ユーザーが解答シートを作成し、回答・正解を入力して自動採点を行い、学習履歴を管理する。

## アーキテクチャ

- **パターン**: MVVM（Model-View-ViewModel）
- **UI**: SwiftUI
- **データ永続化**: UserDefaults
- **対象OS**: iOS 17+
- **言語**: Swift

## ディレクトリ構造

```
TOEICApp/
├── CLAUDE.md              -- このファイル
├── progress.txt           -- 進捗メモリ
├── lessons.md             -- 固有教訓ログ
├── README.md
├── TOEIC.xcodeproj/       -- Xcode プロジェクトファイル
├── TOEIC/                 -- ソースコード本体
│   ├── TOEICApp.swift          -- アプリエントリポイント
│   ├── Models/
│   │   ├── AnswerSheet.swift   -- 解答シートモデル
│   │   └── DataManager.swift   -- UserDefaults 管理
│   ├── ViewModels/
│   │   └── AnswerSheetViewModel.swift
│   └── Views/
│       ├── HomeView.swift
│       ├── ContentView.swift
│       ├── CreateSheetView.swift
│       ├── SheetDetailView.swift
│       ├── AnswerInputView.swift
│       ├── QuestionGridView.swift
│       ├── ScoringResultView.swift
│       ├── HistoryView.swift
│       └── SettingsView.swift
└── .agents/               -- AIエージェントシステム
    ├── config.sh           -- エージェント設定
    ├── prompts/            -- 各エージェントのプロンプト
    └── output/             -- 実行結果の出力先（.gitignore で除外）
```

## TOEIC ドメイン知識

- TOEIC L&R テストは全200問（リスニング100問 + リーディング100問）
- リスニング: Part 1（写真描写 6問）、Part 2（応答 25問）、Part 3（会話 39問）、Part 4（説明文 30問）
- リーディング: Part 5（短文穴埋め 30問）、Part 6（長文穴埋め 16問）、Part 7（読解 54問）
- スコア: リスニング 5-495点、リーディング 5-495点、合計 10-990点
- 各問題は4択（Part 2のみ3択）

## AIエージェントへの重要な指示（過剰な最適化の禁止）

- **SwiftData Predicateの制約**: `AnswerSheet.swift` 内の `statusRaw` プロパティは、SwiftDataの `#Predicate` で enum を直接扱えない制約を回避するために意図的に用意されたものです。「冗長なプロパティ」として削除しないでください。
- **型定義の維持**: `AnswerSheet.swift` にはアプリ全体で使用される型定義（`TOEICTemplate`, `PartScore`, `WrongAnswer` 等）が集約されています。モデルクラスの整理時にこれらを削除しないように注意してください。

## Tech Preferences

- SwiftUI で画面を構築（UIKit は使わない）
- データ永続化は SwiftData を使用。
- 外部ライブラリは極力使用しない
- テストは XCTest のみ（ViewInspector 等の外部ライブラリは不要）
