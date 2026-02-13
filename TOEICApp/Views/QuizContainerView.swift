// QuizContainerView.swift
// TOEICApp - クイズ進行管理コンテナ（Phase 2〜3の核心部分）

import SwiftUI

// MARK: - クイズ全体コンテナ
struct QuizContainerView: View {
    
    let questionSet: QuestionSet
    @StateObject private var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showQuitAlert = false
    
    init(questionSet: QuestionSet) {
        self.questionSet = questionSet
        self._viewModel = StateObject(wrappedValue: QuizViewModel(questionSet: questionSet))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isQuizFinished {
                    // 結果画面
                    ResultView(viewModel: viewModel) {
                        dismiss()
                    }
                } else {
                    // 問題画面
                    QuestionContainerView(viewModel: viewModel)
                }
            }
            .navigationTitle(questionSet.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isQuizFinished {
                        Button("終了") {
                            showQuitAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.isQuizFinished {
                        // タイマー表示
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(viewModel.formattedTime)
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .alert("学習を終了しますか？", isPresented: $showQuitAlert) {
                Button("続ける", role: .cancel) {}
                Button("終了する", role: .destructive) {
                    viewModel.stopTimer()
                    dismiss()
                }
            } message: {
                Text("現在の進捗は保存されません。")
            }
        }
    }
}

// MARK: - 問題コンテナ（プログレスバー + 問題）
struct QuestionContainerView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // プログレスバー
            ProgressBarView(
                progress: viewModel.progress,
                currentIndex: viewModel.currentQuestionIndex + 1,
                total: viewModel.totalQuestions
            )
            .padding(.horizontal)
            .padding(.top, 8)
            
            // 問題表示
            if let question = viewModel.currentQuestion {
                ScrollView {
                    QuestionView(
                        question: question,
                        answerState: viewModel.answerState,
                        showExplanation: viewModel.showExplanation,
                        onAnswer: { index in
                            viewModel.answer(with: index)
                        },
                        onNext: {
                            viewModel.moveToNext()
                        }
                    )
                    .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - プログレスバー
struct ProgressBarView: View {
    let progress: Double
    let currentIndex: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("問題 \(currentIndex) / \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(colors: [.blue, .blue.opacity(0.7)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - 問題表示ビュー（Phase 2〜3の核心）
struct QuestionView: View {
    
    let question: Question
    let answerState: AnswerState
    let showExplanation: Bool
    let onAnswer: (Int) -> Void
    let onNext: () -> Void
    
    private let optionLabels = ["A", "B", "C", "D"]
    
    var isAnswered: Bool { answerState.isAnswered }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // 問題文カード
            QuestionTextCardView(questionText: question.text)
            
            // 選択肢ボタン群
            VStack(spacing: 12) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    AnswerOptionButton(
                        label: optionLabels[index],
                        text: question.options[index],
                        state: buttonState(for: index),
                        isDisabled: isAnswered
                    ) {
                        onAnswer(index)
                    }
                }
            }
            
            // 正誤表示と解説（回答後のみ）
            if isAnswered {
                AnswerFeedbackView(
                    isCorrect: answerState.selectedIndex == question.correctAnswerIndex,
                    explanation: question.explanation,
                    showExplanation: showExplanation
                )
                
                // 次へボタン
                if showExplanation {
                    Button(action: onNext) {
                        HStack {
                            Text("次の問題へ")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // ボタンの状態を決定
    private func buttonState(for index: Int) -> AnswerButtonState {
        guard isAnswered else { return .normal }
        
        if index == question.correctAnswerIndex {
            return .correct
        } else if index == answerState.selectedIndex {
            return .wrong
        } else {
            return .disabled
        }
    }
}

// MARK: - 問題文カード
struct QuestionTextCardView: View {
    let questionText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                Text("問題")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Text(questionText)
                .font(.body)
                .lineSpacing(6)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - 選択肢ボタンの状態
enum AnswerButtonState {
    case normal    // 未選択
    case correct   // 正解
    case wrong     // 不正解（選択した）
    case disabled  // 選択できない（他の選択肢を選んだ後）
    
    var backgroundColor: Color {
        switch self {
        case .normal:   return Color(.systemBackground)
        case .correct:  return Color.green.opacity(0.15)
        case .wrong:    return Color.red.opacity(0.15)
        case .disabled: return Color(.systemBackground).opacity(0.6)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .normal:   return Color.gray.opacity(0.2)
        case .correct:  return Color.green
        case .wrong:    return Color.red
        case .disabled: return Color.gray.opacity(0.1)
        }
    }
    
    var labelBgColor: Color {
        switch self {
        case .normal:   return Color.blue.opacity(0.12)
        case .correct:  return Color.green
        case .wrong:    return Color.red
        case .disabled: return Color.gray.opacity(0.15)
        }
    }
    
    var labelTextColor: Color {
        switch self {
        case .normal:   return Color.blue
        case .correct:  return Color.white
        case .wrong:    return Color.white
        case .disabled: return Color.gray
        }
    }
    
    var textColor: Color {
        switch self {
        case .disabled: return Color.secondary
        default:        return Color.primary
        }
    }
    
    var icon: String? {
        switch self {
        case .correct: return "checkmark.circle.fill"
        case .wrong:   return "xmark.circle.fill"
        default:       return nil
        }
    }
}

// MARK: - 選択肢ボタン
struct AnswerOptionButton: View {
    let label: String
    let text: String
    let state: AnswerButtonState
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // ラベル（A, B, C, D）
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(state.labelTextColor)
                    .frame(width: 32, height: 32)
                    .background(state.labelBgColor)
                    .clipShape(Circle())
                
                // 選択肢テキスト
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(state.textColor)
                
                Spacer()
                
                // 正誤アイコン
                if let icon = state.icon {
                    Image(systemName: icon)
                        .foregroundColor(state == .correct ? .green : .red)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(state.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(state.borderColor, lineWidth: state == .normal ? 1 : 2)
            )
            .cornerRadius(14)
        }
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: state.backgroundColor)
    }
}

// MARK: - 回答フィードバック（正誤 + 解説）
struct AnswerFeedbackView: View {
    let isCorrect: Bool
    let explanation: String
    let showExplanation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 正誤バナー
            HStack(spacing: 10) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(isCorrect ? .green : .red)
                
                Text(isCorrect ? "正解！" : "不正解...")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCorrect ? .green : .red)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(12)
            
            // 解説
            if showExplanation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                        Text("解説")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Text(explanation)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showExplanation)
    }
}

#Preview {
    QuizContainerView(questionSet: SampleData.part5Beginner)
        .environmentObject(DataManager.shared)
}
