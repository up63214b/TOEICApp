// CreateSheetView.swift
// TOEICApp - 新規シート作成 (SwiftData対応)

import SwiftUI
import SwiftData

struct CreateSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var inputOrder: InputOrder = .answerFirst
    
    // エラーハンドリング用
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("タイトル (例: 第300回公開テスト)", text: $title)
                }
                
                Section(header: Text("入力モード")) {
                    Picker("入力順序", selection: $inputOrder) {
                        Text("回答 -> 正解").tag(InputOrder.answerFirst)
                        Text("正解 -> 回答").tag(InputOrder.correctFirst)
                    }
                    .pickerStyle(.segmented)
                    
                    Text(inputOrder == .answerFirst ? 
                         "まず自分の回答を入力し、後で正解を入力して採点します。" : 
                         "先に正解を入力しておき、回答を入力すると即座に採点されます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("新規シート作成")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        createSheet()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createSheet() {
        let finalTitle = title.isEmpty ? "TOEIC解答シート" : title
        let sheet = AnswerSheet(title: finalTitle, inputOrder: inputOrder)
        modelContext.insert(sheet)
        do { try modelContext.save() } catch { print("Failed to save: \(error)") }
    }
}
