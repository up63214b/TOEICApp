// AnswerInputView.swift
// TOEICApp - 回答入力画面

import SwiftUI

struct AnswerInputView: View {

    @ObservedObject var viewModel: AnswerSheetViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 正解を表示するかどうかの設定
    @State private var showCorrectAnswers = false
    
    // 採点結果を表示するかどうかの設定
    @State private var showResult = false
    
    // 正解入力モードが未完了の場合の警告
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
                    HStack(spacing: 16) {
                        // 回答 / 正解入力モード切り替えトグル
                        Button {
                            withAnimation {
                                if viewModel.inputMode == .answer {
                                    viewModel.inputMode = .correct
                                } else {
                                    viewModel.inputMode = .answer
                                }
                            }
                        } label: {
                            Image(systemName: viewModel.inputMode == .answer ? "pencil.circle" : "checkmark.circle.fill")
                                .foregroundColor(viewModel.inputMode == .answer ? .blue : .green)
                        }
                        
                        // 正解を表示して確認するトグル（目のアイコン）
                        Button {
                            showCorrectAnswers.toggle()
                        } label: {
                            Image(systemName: showCorrectAnswers ? "eye.fill" : "eye.slash")
                                .foregroundColor(showCorrectAnswers ? .green : .secondary)
                        }

                        Button {
                            viewModel.showGrid = true
                        } label: {
                            Image(systemName: "square.grid.3x3")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showGrid) {
                QuestionGridView(viewModel: viewModel)
            }
            .sheet(isPresented: $showResult) {
                ScoringResultView(sheet: viewModel.sheet)
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
        ScrollView {
            VStack(spacing: 24) {
                ForEach(viewModel.currentQuestionRange, id: \.self) { qNumber in
                    questionRow(for: qNumber)
                }
            }
            .padding(.horizontal)
        }
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
        let correct = viewModel.sheet.answers[index].correctOption
        let labels = TOEICTemplate.choiceLabels(for: qNumber)
        
        let isMultiSet = (32...100).contains(qNumber)

        return VStack(spacing: 12) {
            HStack {
                Text("Q\(qNumber)")
                    .font(.system(size: isMultiSet ? 24 : (isCurrent ? 32 : 24), weight: .bold, design: .rounded))
                    .foregroundColor(isCurrent ? .blue : .secondary)
                
                Spacer()
                
                if showCorrectAnswers {
                    // 正答確認モード
                    HStack(spacing: 8) {
                        if let answer = answer, let correct = correct {
                            Image(systemName: answer == correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(answer == correct ? .green : .red)
                                .font(.headline)
                        }
                        
                        if let correct = correct {
                            Text(correct)
                                .font(.headline)
                                .foregroundColor(.green)
                        } else {
                            Text("-")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if !isMultiSet && answer != nil {
                    // 単一表示かつ回答済みの場合のみ丸を表示
                    Text(answer ?? "")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    viewModel.currentQuestion = qNumber
                }
            }

            // 選択肢の表示ロジック
            // Q32-100 (isMultiSet) の場合は常に表示。それ以外は isCurrent の場合のみ。
            if isMultiSet || isCurrent {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ForEach(labels, id: \.self) { choice in
                            let isSelected = (viewModel.inputMode == .answer ? answer : correct) == choice
                            
                            ChoiceButton(
                                label: choice,
                                isSelected: isSelected,
                                action: {
                                    viewModel.currentQuestion = qNumber
                                    viewModel.selectChoice(choice)
                                }
                            )
                        }
                    }
                    
                    if isMultiSet && isCurrent {
                        // 3問セットのときはどれを選択中か分かりやすくアンダーライン
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 2)
                            .padding(.horizontal, 4)
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
                withAnimation {
                    viewModel.goPrevious()
                }
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
            .disabled(viewModel.currentQuestionRange.lowerBound <= 1)

            // 次へ / 完了
            if viewModel.currentQuestionRange.upperBound >= TOEICTemplate.totalQuestions {
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
                    withAnimation {
                        viewModel.goNext()
                    }
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
            if viewModel.sheet.inputOrder == .correctFirst {
                // 正解先行パターンの場合、回答完了時に即採点
                viewModel.score()
                showResult = true
            } else {
                // 通常パターン: 回答完了 -> 正解入力へ
                viewModel.finishAnswering()
                dismiss()
            }
        case .correct:
            if viewModel.sheet.status == .correctInput {
                // 正解先行パターン: 正解入力完了
                if viewModel.sheet.correctAnswersEnteredCount < TOEICTemplate.totalQuestions {
                    showIncompleteAlert = true
                    return
                }
                viewModel.finishCorrectInput()
                dismiss()
            } else {
                // 回答先行パターン: 回答後の正解入力完了 -> 採点
                if viewModel.sheet.correctAnswersEnteredCount < TOEICTemplate.totalQuestions {
                    showIncompleteAlert = true
                    return
                }
                viewModel.score()
                showResult = true
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
        Button(action: {
            // 触覚フィードバック
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
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
