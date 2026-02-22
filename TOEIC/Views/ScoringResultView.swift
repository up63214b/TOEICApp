// ScoringResultView.swift
// TOEICApp - 採点結果画面

import SwiftUI

struct ScoringResultView: View {

    let sheet: AnswerSheet
    @Environment(\.dismiss) private var dismiss
    @State private var showWrongAnswers = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // メインスコア
                    mainScoreSection

                    // Listening / Reading
                    sectionScores

                    // パート別内訳
                    partBreakdown

                    // 間違えた問題ボタン
                    if !sheet.wrongAnswers.isEmpty {
                        wrongAnswersButton
                    }

                    // 時間
                    if sheet.elapsedSeconds > 0 {
                        timeSection
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showWrongAnswers) {
                WrongAnswersView(sheet: sheet)
            }
            .navigationTitle("採点結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // MARK: - メインスコアサークル
    private var mainScoreSection: some View {
        VStack(spacing: 12) {
            Text(sheet.title)
                .font(.headline)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: sheet.scorePercentage / 100)
                    .stroke(mainScoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(sheet.totalCorrect)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("/ \(TOEICTemplate.totalQuestions)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", sheet.scorePercentage))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(mainScoreColor)
                }
            }
        }
        .padding(.top, 8)
    }

    private var mainScoreColor: Color {
        switch sheet.scorePercentage {
        case 80...100: return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }

    // MARK: - Listening / Reading セクション
    private var sectionScores: some View {
        HStack(spacing: 16) {
            sectionCard(
                title: "Listening",
                icon: "headphones",
                score: sheet.listeningScore,
                color: .blue
            )
            sectionCard(
                title: "Reading",
                icon: "doc.text",
                score: sheet.readingScore,
                color: .purple
            )
        }
    }

    private func sectionCard(title: String, icon: String, score: PartScore, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)

            Text("\(score.correct) / \(score.total)")
                .font(.title2)
                .fontWeight(.bold)

            Text(String(format: "%.1f%%", score.percentage))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }

    // MARK: - パート別内訳
    private var partBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("パート別内訳")
                .font(.headline)

            ForEach(sheet.partScores) { partScore in
                partRow(partScore)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func partRow(_ partScore: PartScore) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(partScore.part.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(partScore.part.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(partScore.correct)/\(partScore.total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: partScore.percentage))
                        .frame(width: geometry.size.width * (partScore.percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private func barColor(for percentage: Double) -> Color {
        switch percentage {
        case 80...100: return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }

    // MARK: - 間違えた問題ボタン
    private var wrongAnswersButton: some View {
        Button {
            showWrongAnswers = true
        } label: {
            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
                Text("間違えた問題を見る")
                    .fontWeight(.medium)
                Spacer()
                Text("\(sheet.wrongAnswers.count)問")
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .foregroundColor(.primary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - 時間セクション
    private var timeSection: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            Text("回答時間")
                .foregroundColor(.secondary)
            Spacer()
            Text(sheet.formattedTime)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    var sheet = AnswerSheet(title: "公式問題集 Vol.10 Test1")
    // サンプルデータを入れる
    let _ = {
        for i in 1...200 {
            let labels = TOEICTemplate.choiceLabels(for: i)
            sheet.setAnswer(labels.randomElement()!, for: i)
            sheet.setCorrectAnswer(labels.randomElement()!, for: i)
        }
        sheet.elapsedSeconds = 7200
        sheet.status = .scored
    }()
    ScoringResultView(sheet: sheet)
}
