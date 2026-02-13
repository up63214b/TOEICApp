// HomeView.swift
// TOEICApp - ホーム画面（解答シート一覧）

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var dataManager: DataManager
    @State private var showCreateSheet = false
    @State private var createdSheet: AnswerSheet?
    @State private var showAnswerInput = false

    var body: some View {
        NavigationStack {
            Group {
                if dataManager.activeSheets.isEmpty && dataManager.scoredSheets.isEmpty {
                    emptyView
                } else {
                    sheetListView
                }
            }
            .navigationTitle("TOEIC解答シート")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateSheetView { sheet in
                    createdSheet = sheet
                    showAnswerInput = true
                }
            }
            .fullScreenCover(isPresented: $showAnswerInput) {
                if let sheet = createdSheet {
                    let vm = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                    AnswerInputView(viewModel: vm)
                }
            }
        }
    }

    // MARK: - 空の状態
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("解答シートがありません")
                .font(.title3)
                .fontWeight(.semibold)

            Text("「+」ボタンをタップして\n新しい解答シートを作成しましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreateSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("解答シートを作成")
                }
                .fontWeight(.semibold)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - シートリスト
    private var sheetListView: some View {
        List {
            // 進行中のシート
            if !dataManager.activeSheets.isEmpty {
                Section("進行中") {
                    ForEach(dataManager.activeSheets) { sheet in
                        NavigationLink(destination: SheetDetailView(sheet: sheet)) {
                            SheetRowView(sheet: sheet)
                        }
                    }
                    .onDelete(perform: deleteActiveSheets)
                }
            }

            // 最近の採点済みシート（最大5件）
            let recentScored = Array(dataManager.scoredSheets.prefix(5))
            if !recentScored.isEmpty {
                Section("最近の採点済み") {
                    ForEach(recentScored) { sheet in
                        NavigationLink(destination: SheetDetailView(sheet: sheet)) {
                            ScoredSheetRowView(sheet: sheet)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteActiveSheets(at offsets: IndexSet) {
        for index in offsets {
            let sheet = dataManager.activeSheets[index]
            dataManager.deleteSheet(sheet)
        }
    }
}

// MARK: - シート行（進行中）
struct SheetRowView: View {
    let sheet: AnswerSheet

    private var statusColor: Color {
        switch sheet.status {
        case .answering: return .blue
        case .answered:  return .orange
        case .scoring:   return .purple
        case .scored:    return .green
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // ステータスアイコン
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("\(sheet.answeredCount)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sheet.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(sheet.status.label)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.12))
                        .cornerRadius(4)

                    Text("\(sheet.answeredCount)/200問")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if sheet.elapsedSeconds > 0 {
                        Text(sheet.formattedTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - シート行（採点済み）
struct ScoredSheetRowView: View {
    let sheet: AnswerSheet

    var scoreColor: Color {
        switch sheet.scorePercentage {
        case 80...100: return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // スコアサークル
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(format: "%.0f", sheet.scorePercentage))
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sheet.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(sheet.totalCorrect)/200問正解")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if sheet.elapsedSeconds > 0 {
                        Text(sheet.formattedTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager.shared)
}
