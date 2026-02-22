// StatisticsView.swift
// TOEICApp - 学習統計画面

import SwiftUI
import Charts
import SwiftData

struct StatisticsView: View {
    @Query(sort: \AnswerSheet.createdAt, order: .forward) private var allSheets: [AnswerSheet]
    
    private var scoredSheets: [AnswerSheet] {
        allSheets.filter { $0.status == .scored }
    }
    
    private var hasData: Bool {
        !allSheets.isEmpty
    }
    
    private var totalAnsweredCount: Int {
        allSheets.reduce(0) { $0 + $1.answeredCount }
    }
    
    private var averageScore: Double {
        guard !scoredSheets.isEmpty else { return 0 }
        let total = scoredSheets.reduce(0.0) { $0 + $1.scorePercentage }
        return total / Double(scoredSheets.count)
    }
    
    private var learningDays: Int {
        let dates = Set(allSheets.map { Calendar.current.startOfDay(for: $0.createdAt) })
        return dates.count
    }

    var body: some View {
        Group {
            if !hasData {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // 主要な指標カード
                        summarySection
                        
                        // 回答アクティビティ（過去7日間）
                        activitySection
                        
                        // スコアトレンド
                        if scoredSheets.count >= 2 {
                            trendSection
                        } else if scoredSheets.count == 1 {
                            infoCard(text: "2回以上受験すると、ここにスコア推移が表示されます。")
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("学習統計")
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - サブビュー
    
    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                summaryCard(title: "総回答数", value: "\(totalAnsweredCount)", unit: "問", icon: "pencil.and.outline", color: .blue)
                summaryCard(title: "受験回数", value: "\(scoredSheets.count)", unit: "回", icon: "doc.plaintext", color: .green)
            }
            HStack(spacing: 16) {
                summaryCard(title: "平均正解率", value: String(format: "%.0f", averageScore), unit: "%", icon: "target", color: .orange)
                summaryCard(title: "学習日数", value: "\(learningDays)", unit: "日", icon: "calendar", color: .purple)
            }
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("直近7日間の学習量", systemImage: "flame.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            Chart {
                ForEach(dailyQuestionCounts, id: \.date) { data in
                    BarMark(
                        x: .value("日付", data.date, unit: .day),
                        y: .value("回答数", data.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("スコア推移", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundColor(.green)
            
            Chart {
                ForEach(scoreHistory, id: \.index) { data in
                    LineMark(
                        x: .value("回数", data.index),
                        y: .value("正解率", data.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("回数", data.index),
                        y: .value("正解率", data.score)
                    )
                    .foregroundStyle(Color.green.opacity(0.1).gradient)
                }
                
                RuleMark(y: .value("目標", 80))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .leading) {
                        Text("目標 80%")
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                    }
            }
            .frame(height: 180)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) { _ in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("統計データがまだありません")
                .font(.title3.bold())
            
            Text("解答シートを作成して学習を始めると、ここに分析結果が表示されます。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - ヘルパー
    
    private func summaryCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private func infoCard(text: String) -> some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var dailyQuestionCounts: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        let last7Days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }.reversed()
        
        return last7Days.map { date in
            let count = allSheets.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
                .reduce(0) { $0 + $1.answeredCount }
            return (date: date, count: count)
        }
    }
    
    private var scoreHistory: [(index: Int, score: Double)] {
        scoredSheets.enumerated().map { (index, sheet) in
            (index: index + 1, score: sheet.scorePercentage)
        }
    }
}
