// HistoryView.swift
// TOEICApp - 履歴画面 (SwiftData対応)

import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 採点済みシートを取得（3 = .scored）
    @Query(filter: #Predicate<AnswerSheet> { $0.statusRaw == 3 }, sort: \AnswerSheet.createdAt, order: .reverse)
    private var scoredSheets: [AnswerSheet]
    
    @State private var showDeleteConfirm = false
    
    private var averageScore: Double {
        guard !scoredSheets.isEmpty else { return 0 }
        let total = scoredSheets.reduce(0.0) { $0 + $1.scorePercentage }
        return total / Double(scoredSheets.count)
    }
    
    private var scoreHistoryForChart: [(index: Int, score: Double)] {
        // グラフは左から右へ時系列順にしたいので、古いものから並べる
        scoredSheets.reversed().enumerated().map { (index, sheet) in
            (index: index + 1, score: sheet.scorePercentage)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scoredSheets.isEmpty {
                    emptyView
                } else {
                    historyList
                }
            }
            .navigationTitle("履歴")
            .toolbar {
                if !scoredSheets.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("履歴の全削除", isPresented: $showDeleteConfirm) {
                Button("採点済みシートをすべて削除", role: .destructive) {
                    deleteScoredSheets()
                }
            } message: {
                Text("採点済みの履歴データをすべて削除してもよろしいですか？")
            }
        }
    }

    private var historyList: some View {
        List {
            Section(header: Text("統計")) {
                statisticsSection
            }
            
            ForEach(groupedSheets, id: \.key) { month, sheets in
                Section(header: Text(month)) {
                    ForEach(sheets) { sheet in
                        NavigationLink(destination: SheetDetailView(sheet: sheet)) {
                            HistoryRowView(sheet: sheet)
                        }
                    }
                }
            }
        }
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                statisticItem(title: "受験数", value: "\(scoredSheets.count)", color: .blue)
                Divider()
                statisticItem(title: "平均正解率", value: String(format: "%.0f%%", averageScore), color: .green)
            }
            
            if scoredSheets.count >= 2 {
                scoreTrendChart
            }
        }
        .padding(.vertical, 8)
    }
    
    private var scoreTrendChart: some View {
        VStack(alignment: .leading) {
            Text("スコア推移")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(scoreHistoryForChart, id: \.index) { data in
                    LineMark(
                        x: .value("回数", data.index),
                        y: .value("正解率", data.score)
                    )
                    .foregroundStyle(Color.green.gradient)
                    
                    AreaMark(
                        x: .value("回数", data.index),
                        y: .value("正解率", data.score)
                    )
                    .foregroundStyle(Color.green.opacity(0.1).gradient)
                }
            }
            .frame(height: 100)
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
    }

    private func statisticItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("履歴がありません")
                .font(.headline)
            Text("採点済みのシートがここに表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var groupedSheets: [(key: String, value: [AnswerSheet])] {
        let grouped = Dictionary(grouping: scoredSheets) { sheet in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: sheet.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func deleteScoredSheets() {
        for sheet in scoredSheets {
            modelContext.delete(sheet)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}

struct HistoryRowView: View {
    let sheet: AnswerSheet
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sheet.title)
                    .font(.subheadline.bold())
                Text(sheet.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(sheet.totalCorrect) / 200")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text(String(format: "%.1f%%", sheet.scorePercentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
