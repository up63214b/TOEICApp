// TOEICApp.swift
// TOEIC - アプリエントリーポイント

import SwiftUI
import SwiftData

@main
struct TOEICApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // View階層全体でSwiftDataのコンテナ（データベース）を利用可能にする
        .modelContainer(for: AnswerSheet.self)
    }
}
