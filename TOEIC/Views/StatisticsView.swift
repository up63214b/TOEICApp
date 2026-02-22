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
    
    // 最近7日間の回答問題数
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
    
    // スコア推移
    private var scoreHistory: [(index: Int, score: Double)] {
        scoredSheets.enumerated().map { (index, sheet) in
            (index: index + 1, score: sheet.scorePercentage * 100)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 学習概要
                summaryCards
                
                // 回答数の推移（棒グラフ）
                dailyActivityChart
                
                // スコア推移（折れ線グラフ）
                if scoreHistory.count >= 2 {
                    scoreTrendChart
                }
            }
            .padding()
        }
        .navigationTitle("学習統計")
        .background(Color(.systemGroupedBackground))
    }
    
    private var summaryCards: some View {
        HStack(spacing: 16) {
            summaryCard(title: "総回答数", value: "\(allSheets.reduce(0) { $0 + $1.answeredCount })", icon: "pencil.and.outline", color: .blue)
            summaryCard(title: "受験回数", value: "\(scoredSheets.count)", icon: "doc.plaintext", color: .green)
        }
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var dailyActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近7日間の回答数")
                .font(.headline)
            
            Chart {
                ForEach(dailyQuestionCounts, id: \.date) { data in
                    BarMark(
                        x: .value("日付", data.date, unit: .day),
                        y: .value("回答数", data.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var scoreTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("スコア推移")
                .font(.headline)
            
            Chart {
                ForEach(scoreHistory, id: \.index) { data in
                    LineMark(
                        x: .value("回数", data.index),
                        y: .value("正解率", data.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.green)
                    .symbol(Circle())
                    
                    AreaMark(
                        x: .value("回数", data.index),
                        y: .value("正解率", data.score)
                    )
                    .foregroundStyle(Color.green.opacity(0.1).gradient)
                }
                
                // 目標ライン (例: 80%)
                RuleMark(y: .value("目標", 80))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .leading) {
                        Text("目標 (80%)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
            }
            .frame(height: 150)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: 1))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}
