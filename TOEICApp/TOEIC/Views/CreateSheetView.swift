// CreateSheetView.swift
// TOEICApp - 新規解答シート作成フォーム

import SwiftUI

struct CreateSheetView: View {

    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool

    /// 作成後に解答シートを返す
    var onCreated: ((AnswerSheet) -> Void)?

    private var defaultTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return "TOEIC \(formatter.string(from: Date()))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("シートタイトル") {
                    TextField("例: TOEIC公式問題集 Vol.10 Test1", text: $title)
                        .focused($isTitleFocused)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("TOEIC L&R 全200問", systemImage: "doc.text")
                            .font(.body)

                        HStack(spacing: 16) {
                            InfoBadge(label: "Listening", value: "Part 1-4 (100問)")
                            InfoBadge(label: "Reading", value: "Part 5-7 (100問)")
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("テスト構成")
                }
            }
            .navigationTitle("新規解答シート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createSheet()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                title = defaultTitle
                isTitleFocused = true
            }
        }
    }

    private func createSheet() {
        let sheetTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = sheetTitle.isEmpty ? defaultTitle : sheetTitle
        let sheet = AnswerSheet(title: finalTitle)
        dataManager.addSheet(sheet)
        onCreated?(sheet)
        dismiss()
    }
}

// MARK: - 情報バッジ
struct InfoBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CreateSheetView()
        .environmentObject(DataManager.shared)
}
