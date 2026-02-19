// QuestionGridView.swift
// TOEICApp - 200問一覧グリッド（問題番号ジャンプ用）

import SwiftUI

struct QuestionGridView: View {

    @ObservedObject var viewModel: AnswerSheetViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 10)

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(TOEICTemplate.partRanges, id: \.part) { part, range in
                            partSection(part: part, range: range)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    // 現在の問題のパートまでスクロール
                    proxy.scrollTo(viewModel.currentPart, anchor: .top)
                }
            }
            .navigationTitle("問題一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func partSection(part: TOEICPart, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // パートヘッダー
            HStack {
                Text(part.name)
                    .font(.headline)
                Text(part.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .id(part)

            // グリッド
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(range), id: \.self) { number in
                    gridCell(number: number)
                }
            }
        }
    }

    private func gridCell(number: Int) -> some View {
        let status = viewModel.answerStatus(for: number)
        return Button {
            viewModel.goToQuestion(number)
            dismiss()
        } label: {
            Text("\(number)")
                .font(.system(size: 11, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(cellBackgroundColor(status))
                .foregroundColor(cellForegroundColor(status))
                .cornerRadius(6)
        }
    }

    private func cellBackgroundColor(_ status: AnswerCellStatus) -> Color {
        switch status {
        case .unanswered: return Color(.systemGray6)
        case .current:    return Color.blue.opacity(0.3)
        case .answered:   return Color.blue
        }
    }

    private func cellForegroundColor(_ status: AnswerCellStatus) -> Color {
        switch status {
        case .unanswered: return .secondary
        case .current:    return .blue
        case .answered:   return .white
        }
    }
}

#Preview {
    let sheet = AnswerSheet(title: "テスト")
    let vm = AnswerSheetViewModel(sheet: sheet, dataManager: DataManager.shared)
    QuestionGridView(viewModel: vm)
}
