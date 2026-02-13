// ContentView.swift
// TOEICApp - メイン画面（タブナビゲーション）

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // ホーム・問題集選択タブ
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
            
            // 復習タブ
            ReviewView()
                .tabItem {
                    Label("復習", systemImage: "arrow.counterclockwise.circle.fill")
                }
            
            // 学習履歴タブ
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
            
            // 設定タブ
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
        .environmentObject(DataManager.shared)
}
