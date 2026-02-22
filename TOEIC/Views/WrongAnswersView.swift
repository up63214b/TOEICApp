// WrongAnswersView.swift
// TOEICApp - 間違えた問題一覧画面

import SwiftUI

struct WrongAnswersView: View {

    let sheet: AnswerSheet
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: AnswerFilter = .all

    // フィルター種別
    enum AnswerFilter: Hashable {
        case all
        case listening
        case reading
        case part(TOEICPart)
    }

    // フィルター適用後の間違い一覧
    private var filteredWrongAnswers: [WrongAnswer] {
        switch selectedFilter {
        case .all:
            return sheet.wrongAnswers
        case .listening:
            return sheet.wrongAnswers.filter { $0.part.isListening }
        case .reading:
            return sheet.wrongAnswers.filter { !$0.part.isListening }
        case .part(let part):
            return sheet.wrongAnswers.filter { $0.part == part }
        }
    }

    // パート別にグループ化
    private var groupedWrongAnswers: [(part: TOEICPart, answers: [WrongAnswer])] {
        let grouped = Dictionary(grouping: filteredWrongAnswers) { $0.part }
        return TOEICPart.allCases.compactMap { part in
            guard let answers = grouped[part], !answers.isEmpty else { return nil }
            return (part: part, answers: answers)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // フィルターバー
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                if filteredWrongAnswers.isEmpty {
                    // 間違いなし
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("間違えた問題はありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // 間違い一覧
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(groupedWrongAnswers, id: \.part) { group in
                                partSection(group.part, answers: group.answers)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("間違えた問題 (\(filteredWrongAnswers.count)問)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // MARK: - フィルターバー
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("全て", filter: .all)
                filterChip("L", filter: .listening)
                filterChip("R", filter: .reading)

                Divider()
                    .frame(height: 24)

                ForEach(TOEICPart.allCases) { part in
                    filterChip(part.name, filter: .part(part))
                }
            }
        }
    }

    private func filterChip(_ label: String, filter: AnswerFilter) -> some View {
        let isActive = selectedFilter == filter
        return Button {
            selectedFilter = filter
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isActive ? Color.blue : Color(.systemGray5))
                .foregroundColor(isActive ? .white : .primary)
                .cornerRadius(8)
        }
    }

    // MARK: - パート別セクション
    private func partSection(_ part: TOEICPart, answers: [WrongAnswer]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // セクションヘッダー
            HStack {
                Image(systemName: part.icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("\(part.name) - \(part.description)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(answers.count)問")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 各問題の行
            VStack(spacing: 0) {
                ForEach(answers) { wrong in
                    wrongAnswerRow(wrong)

                    if wrong.id != answers.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        }
    }

    private func wrongAnswerRow(_ wrong: WrongAnswer) -> some View {
        HStack {
            // 問題番号
            Text("Q\(wrong.questionNumber)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 50, alignment: .leading)

            Spacer()

            // ユーザーの回答
            HStack(spacing: 4) {
                Text("あなた:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(wrong.userAnswer ?? "--")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }

            Spacer()

            // 正解
            HStack(spacing: 4) {
                Text("正解:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(wrong.correctAnswer)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

#Preview {
    var sheet = AnswerSheet(title: "テスト")
    let _ = {
        for i in 1...200 {
            let labels = TOEICTemplate.choiceLabels(for: i)
            sheet.setAnswer(labels.randomElement()!, for: i)
            sheet.setCorrectAnswer(labels.randomElement()!, for: i)
        }
        sheet.status = .scored
    }()
    WrongAnswersView(sheet: sheet)
}
