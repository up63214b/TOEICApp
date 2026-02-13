// HistoryView.swift
// TOEICApp - 学習履歴画面（Phase 4）

import SwiftUI

struct HistoryView: View {
    
    @EnvironmentObject var dataManager: DataManager
    @State private var showClearAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if dataManager.studyHistory.isEmpty {
                    EmptyHistoryView()
                } else {
                    HistoryListView()
                }
            }
            .navigationTitle("学習履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !dataManager.studyHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("クリア") {
                            showClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("履歴を削除", isPresented: $showClearAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    dataManager.clearHistory()
                }
            } message: {
                Text("すべての学習履歴を削除します。この操作は元に戻せません。")
            }
        }
    }
}

// MARK: - 履歴なし表示
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("学習履歴がありません")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("問題集を解くと\nここに記録されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - 履歴リスト
struct HistoryListView: View {
    
    @EnvironmentObject var dataManager: DataManager
    
    // 日付でグループ化
    var groupedHistory: [(String, [StudyHistory])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let grouped = Dictionary(grouping: dataManager.studyHistory) { history in
            formatter.string(from: history.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        List {
            // 統計サマリー
            Section {
                HistorySummaryView()
            }
            
            // 履歴リスト（日付グループ）
            ForEach(groupedHistory, id: \.0) { date, histories in
                Section(header: Text(date)) {
                    ForEach(histories) { history in
                        HistoryRowView(history: history)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - 統計サマリー
struct HistorySummaryView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("学習サマリー")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 0) {
                SummaryItem(
                    value: "\(dataManager.totalStudySessions)",
                    label: "学習回数",
                    color: .blue
                )
                Divider().frame(height: 40)
                SummaryItem(
                    value: "\(dataManager.totalQuestionsAnswered)",
                    label: "総回答数",
                    color: .purple
                )
                Divider().frame(height: 40)
                SummaryItem(
                    value: String(format: "%.0f%%", dataManager.averageScore),
                    label: "平均正解率",
                    color: .green
                )
            }
        }
        .padding(.vertical, 4)
    }
}

struct SummaryItem: View {
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

// MARK: - 履歴行
struct HistoryRowView: View {
    let history: StudyHistory
    
    var scoreColor: Color {
        switch history.scorePercentage {
        case 80...100: return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: history.date)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // スコアサークル（小）
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Text(String(format: "%.0f", history.scorePercentage))
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            
            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(history.questionSetTitle)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Label(history.formattedScore, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(history.formattedTimeSpent, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(formattedTime)
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
