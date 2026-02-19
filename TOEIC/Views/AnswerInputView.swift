// AnswerInputView.swift
// TOEICApp - 回答入力画面

import SwiftUI

struct AnswerInputView: View {

    @ObservedObject var viewModel: AnswerSheetViewModel
    @Environment(\.dismiss) private var dismiss
    // 正解入力が未完了のまま完了ボタンが押された場合の確認アラート（#6対応）
    @State private var showIncompleteAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー: パート情報 + タイマー
                headerSection

                Divider()

                // メインコンテンツ: 問題番号 + 選択肢
                Spacer()
                questionSection
                Spacer()

                // プログレスバー
                progressSection

                // ナビゲーションボタン
                navigationSection
            }
            .navigationTitle(viewModel.inputMode == .answer ? "回答入力" : "正解入力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        viewModel.stopTimer()
                        viewModel.saveToStorage()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showGrid = true
                    } label: {
                        Image(systemName: "square.grid.3x3")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showGrid) {
                QuestionGridView(viewModel: viewModel)
            }
            .alert("正解入力が未完了です", isPresented: $showIncompleteAlert) {
                Button("続ける", role: .cancel) {}
                Button("このまま閉じる", role: .destructive) {
                    viewModel.score()
                    dismiss()
                }
            } message: {
                Text("\(viewModel.sheet.correctAnswersEnteredCount) / \(TOEICTemplate.totalQuestions) 問しか入力されていません。このまま閉じると未入力の問題は採点されません。")
            }
            .onAppear {
                // #7: startTimer() 内で guard !isTimerRunning により二重起動は防止済み
                if viewModel.inputMode == .answer {
                    viewModel.startTimer()
                }
            }
        }
    }

    // MARK: - ヘッダー
    private var headerSection: some View {
        HStack {
            // パート情報
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentPart.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Text(viewModel.currentPart.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // タイマー（回答入力モードのみ表示）
            if viewModel.inputMode == .answer {
                Button {
                    viewModel.toggleTimer()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.caption2)
                        Text(viewModel.sheet.formattedTime)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.isTimerRunning ? .blue : .secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - 問題セクション
    private var questionSection: some View {
        VStack(spacing: 32) {
            // 問題番号
            Text("Q\(viewModel.currentQuestion)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // 選択肢ボタン
            HStack(spacing: 16) {
                ForEach(viewModel.choiceLabels, id: \.self) { choice in
                    ChoiceButton(
                        label: choice,
                        isSelected: viewModel.currentAnswer == choice,
                        action: {
                            viewModel.selectChoice(choice)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)

            // クリアボタン
            if viewModel.currentAnswer != nil {
                Button {
                    viewModel.clearCurrentAnswer()
                } label: {
                    Text("クリア")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - プログレス
    private var progressSection: some View {
        VStack(spacing: 6) {
            ProgressView(value: viewModel.progress)
                .tint(.blue)
                .padding(.horizontal)

            Text(viewModel.progressText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - ナビゲーション
    private var navigationSection: some View {
        HStack(spacing: 20) {
            // 前へ
            Button {
                viewModel.goPrevious()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("前へ")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(viewModel.currentQuestion <= 1)

            // 次へ / 完了
            if viewModel.currentQuestion >= TOEICTemplate.totalQuestions {
                Button {
                    handleFinish()
                } label: {
                    Text("完了")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                Button {
                    viewModel.goNext()
                } label: {
                    HStack {
                        Text("次へ")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private func handleFinish() {
        switch viewModel.inputMode {
        case .answer:
            viewModel.finishAnswering()
            dismiss()
        case .correct:
            // 正解が未完了の場合は確認アラートを出す（#6対応）
            if viewModel.sheet.correctAnswersEnteredCount < TOEICTemplate.totalQuestions {
                showIncompleteAlert = true
                return
            }
            viewModel.score()
            dismiss()
        }
    }
}

// MARK: - 選択肢ボタン
struct ChoiceButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title)
                .fontWeight(.bold)
                .frame(width: 64, height: 64)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

#Preview {
    let sheet = AnswerSheet(title: "テスト")
    let vm = AnswerSheetViewModel(sheet: sheet, dataManager: DataManager.shared)
    AnswerInputView(viewModel: vm)
}
