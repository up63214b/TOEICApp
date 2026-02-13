// SettingsView.swift
// TOEICApp - 設定画面

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("showExplanationImmediately") var showExplanationImmediately = true
    @AppStorage("shuffleQuestions") var shuffleQuestions = false
    @AppStorage("soundEnabled") var soundEnabled = true
    
    @State private var showClearHistoryAlert = false
    @State private var showClearWrongQuestionsAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // 学習設定
                Section("学習設定") {
                    Toggle(isOn: $showExplanationImmediately) {
                        Label("回答後すぐに解説を表示", systemImage: "lightbulb.fill")
                    }
                    .tint(.blue)
                    
                    Toggle(isOn: $shuffleQuestions) {
                        Label("問題をシャッフルする", systemImage: "shuffle")
                    }
                    .tint(.blue)
                }
                
                // データ管理
                Section("データ管理") {
                    // 学習履歴件数
                    HStack {
                        Label("学習履歴", systemImage: "clock.fill")
                        Spacer()
                        Text("\(dataManager.studyHistory.count)件")
                            .foregroundColor(.secondary)
                    }
                    
                    // 要復習件数
                    HStack {
                        Label("要復習リスト", systemImage: "exclamationmark.circle.fill")
                        Spacer()
                        Text("\(dataManager.wrongQuestionsCount)問")
                            .foregroundColor(.secondary)
                    }
                    
                    // 履歴クリアボタン
                    Button(role: .destructive) {
                        showClearHistoryAlert = true
                    } label: {
                        Label("学習履歴を削除", systemImage: "trash")
                    }
                    
                    // 復習リストクリア
                    Button(role: .destructive) {
                        showClearWrongQuestionsAlert = true
                    } label: {
                        Label("復習リストをクリア", systemImage: "xmark.circle")
                    }
                }
                
                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Label("バージョン", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("問題数", systemImage: "doc.text")
                        Spacer()
                        Text("\(SampleData.allQuestionSets.flatMap { $0.questions }.count)問")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 免責事項
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("免責事項")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("TOEIC® is a registered trademark of ETS. This product is not endorsed or approved by ETS.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            // 学習履歴削除確認ダイアログ
            .alert("学習履歴を削除しますか？", isPresented: $showClearHistoryAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    dataManager.clearHistory()
                }
            } message: {
                Text("すべての学習履歴が削除されます。この操作は元に戻せません。")
            }
            // 復習リスト削除確認ダイアログ
            .alert("復習リストをクリアしますか？", isPresented: $showClearWrongQuestionsAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("クリアする", role: .destructive) {
                    dataManager.clearWrongQuestions()
                }
            } message: {
                Text("要復習としてマークされたすべての問題がリストから削除されます。")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}
