// SettingsView.swift
// TOEICApp - 設定画面 (SwiftData対応)

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sheets: [AnswerSheet]
    
    @State private var showDeleteAlert = false
    
    private var totalSheets: Int {
        sheets.count
    }
    
    private var totalScoredSheets: Int {
        sheets.filter { $0.status == .scored }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("データ統計")) {
                    HStack {
                        Text("作成済みシート数")
                        Spacer()
                        Text("\(totalSheets)件")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("採点済みシート数")
                        Spacer()
                        Text("\(totalScoredSheets)件")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("データ管理"), footer: Text("※削除したデータは元に戻せません。")) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("すべてのデータを削除")
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .alert("全データ削除", isPresented: $showDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    clearAllSheets()
                }
            } message: {
                Text("すべての解答シート履歴を削除してもよろしいですか？")
            }
        }
    }
    
    private func clearAllSheets() {
        for sheet in sheets {
            modelContext.delete(sheet)
        }
        do { try modelContext.save() } catch { print("Failed to save: \(error)") }
    }
}
