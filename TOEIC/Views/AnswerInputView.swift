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
                    if viewModel.sheet.status == .correctInput {
                        // 正解先行パターン: 未完了でも correctReady に遷移
                        viewModel.finishCorrectInput()
                    } else {
                        // 回答先行パターン: 未完了でも採点
                        viewModel.score()
                    }
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
            .onDisappear {
                viewModel.stopTimer()
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
        VStack(spacing: 24) {
            ForEach(viewModel.currentQuestionRange, id: \.self) { qNumber in
                questionRow(for: qNumber)
                    .padding(.vertical, 8)
                    .background(viewModel.currentQuestion == qNumber ? Color.blue.opacity(0.05) : Color.clear)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        // 左右スワイプで問題移動
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if value.translation.width < -50 {
                            viewModel.goNext()
                        } else if value.translation.width > 50 {
                            viewModel.goPrevious()
                        }
                    }
                }
        )
    }

    private func questionRow(for qNumber: Int) -> some View {
        let isCurrent = viewModel.currentQuestion == qNumber
        let index = qNumber - 1
        let answer = viewModel.sheet.answers[index].selectedOption
        let labels = TOEICTemplate.choiceLabels(for: qNumber)

        return VStack(spacing: 12) {
            HStack {
                Text("Q\(qNumber)")
                    .font(.system(size: isCurrent ? 32 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrent ? .primary : .secondary)
                
                Spacer()
                
                if let answer = answer {
                    Text(answer)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .onTapGesture {
                viewModel.currentQuestion = qNumber
            }

            if isCurrent {
                HStack(spacing: 12) {
                    ForEach(labels, id: \.self) { choice in
                        ChoiceButton(
                            label: choice,
                            isSelected: answer == choice,
                            action: {
                                viewModel.currentQuestion = qNumber
                                viewModel.selectChoice(choice)
                            }
                        )
                        .scaleEffect(isCurrent ? 1.0 : 0.8)
                    }
                }
                .transition(.opacity.combined(with: .scale))
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
            if viewModel.sheet.status == .correctInput {
                // 正解先行パターン: 正解入力完了 → correctReady へ
                if viewModel.sheet.correctAnswersEnteredCount < TOEICTemplate.totalQuestions {
                    showIncompleteAlert = true
                    return
                }
                viewModel.finishCorrectInput()
                dismiss()
            } else {
                // 回答先行パターン: 正解入力完了 → 採点
                if viewModel.sheet.correctAnswersEnteredCount < TOEICTemplate.totalQuestions {
                    showIncompleteAlert = true
                    return
                }
                viewModel.score()
                dismiss()
            }
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
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
    }
}

#Preview {
    let sheet = AnswerSheet(title: "テスト")
    let vm = AnswerSheetViewModel(sheet: sheet)
    AnswerInputView(viewModel: vm)
}
