// ContentView.swift
// TOEICApp - メイン画面（タブナビゲーション）

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // ホーム: 解答シート一覧
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            // 履歴: 採点済みシート
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }

            // 設定
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        
}
