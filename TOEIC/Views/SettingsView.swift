// SettingsView.swift
// TOEICApp - 設定画面

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var dataManager: DataManager
    @State private var showClearAllAlert = false

    var body: some View {
        NavigationStack {
            List {
                // データ管理
                Section("データ管理") {
                    HStack {
                        Label("解答シート数", systemImage: "doc.text.fill")
                        Spacer()
                        Text("\(dataManager.totalSheets)件")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("採点済み", systemImage: "checkmark.circle.fill")
                        Spacer()
                        Text("\(dataManager.totalScoredSheets)件")
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        showClearAllAlert = true
                    } label: {
                        Label("全データを削除", systemImage: "trash")
                    }
                }

                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Label("バージョン", systemImage: "info.circle")
                        Spacer()
                        Text("2.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("テスト形式", systemImage: "doc.text")
                        Spacer()
                        Text("TOEIC L&R 200問")
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
                        Text("TOEIC\u{00AE} is a registered trademark of ETS. This product is not endorsed or approved by ETS.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .alert("全データを削除しますか？", isPresented: $showClearAllAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    dataManager.clearAllSheets()
                }
            } message: {
                Text("すべての解答シートが削除されます。この操作は元に戻せません。")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}
