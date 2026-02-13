// TOEICApp.swift
// TOEIC - アプリエントリーポイント

import SwiftUI

@main
struct TOEICApp: App {

    // DataManagerをアプリ全体で共有
    @StateObject private var dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
