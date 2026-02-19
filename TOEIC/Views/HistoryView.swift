// HistoryView.swift
// TOEICApp - 採点済みシートの履歴画面

import SwiftUI

struct HistoryView: View {

    @EnvironmentObject var dataManager: DataManager
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if dataManager.scoredSheets.isEmpty {
                    emptyView
                } else {
                    historyListView
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !dataManager.scoredSheets.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("クリア") {
                            showClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("採点済みシートを全て削除しますか？", isPresented: $showClearAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    for sheet in dataManager.scoredSheets {
                        dataManager.deleteSheet(sheet)
                    }
                }
            } message: {
                Text("採点済みの全シートが削除されます。この操作は元に戻せません。")
            }
        }
    }

    // MARK: - 空の状態
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("採点済みシートがありません")
                .font(.title3)
                .fontWeight(.semibold)

            Text("解答シートを採点すると\nここに記録されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 履歴リスト
    private var historyListView: some View {
        List {
            // サマリーセクション
            Section {
                historySummary
            }

            // 日付別グループ
            ForEach(groupedHistory, id: \.0) { date, sheets in
                Section(header: Text(date)) {
                    ForEach(sheets) { sheet in
                        NavigationLink(destination: SheetDetailView(sheet: sheet)) {
                            HistorySheetRowView(sheet: sheet)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - サマリー
    private var historySummary: some View {
        VStack(spacing: 12) {
            Text("採点サマリー")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                SummaryStatView(
                    value: "\(dataManager.totalScoredSheets)",
                    label: "採点回数",
                    color: .blue
                )
                Divider().frame(height: 40)
                SummaryStatView(
                    value: String(format: "%.0f%%", dataManager.averageScore),
                    label: "平均正解率",
                    color: .green
                )
            }
        }
        .padding(.vertical, 4)
    }

    // body 再評価のたびに生成しないよう static で1度だけインスタンス化（#4対応）
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年MM月dd日"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    // 日付グループ
    private var groupedHistory: [(String, [AnswerSheet])] {
        let grouped = Dictionary(grouping: dataManager.scoredSheets) { sheet in
            Self.dateFormatter.string(from: sheet.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

// MARK: - サマリー統計
struct SummaryStatView: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 履歴シート行
struct HistorySheetRowView: View {
    let sheet: AnswerSheet

    var scoreColor: Color {
        switch sheet.scorePercentage {
        case 80...100: return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: sheet.createdAt)
    }

    var body: some View {
        HStack(spacing: 14) {
            // スコアサークル
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 48, height: 48)

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
                    Label("\(sheet.totalCorrect)/\(TOEICTemplate.totalQuestions)", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if sheet.elapsedSeconds > 0 {
                        Label(sheet.formattedTime, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environmentObject(DataManager.shared)
}
