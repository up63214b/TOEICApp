// ResultView.swift
// TOEICApp - 結果画面（Phase 3）

import SwiftUI

struct ResultView: View {
    
    @ObservedObject var viewModel: QuizViewModel
    let onDismiss: () -> Void
    
    @State private var showDetails = false
    @State private var animateScore = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // スコアサークル
                ScoreCircleView(
                    score: viewModel.scorePercentage,
                    correct: viewModel.correctCount,
                    total: viewModel.totalQuestions,
                    animate: animateScore
                )
                .padding(.top, 20)
                
                // メッセージ
                Text(viewModel.resultMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // 統計情報カード
                StatsCardView(
                    correctCount: viewModel.correctCount,
                    totalQuestions: viewModel.totalQuestions,
                    timeSpent: viewModel.formattedTime,
                    wrongCount: viewModel.totalQuestions - viewModel.correctCount
                )
                .padding(.horizontal)
                
                // アクションボタン
                VStack(spacing: 12) {
                    // ホームに戻る
                    Button(action: onDismiss) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("ホームに戻る")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    
                    // 間違えた問題のみ表示（あれば）
                    if viewModel.correctCount < viewModel.totalQuestions {
                        Button(action: { showDetails = true }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("間違えた問題を確認")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange.opacity(0.12))
                            .foregroundColor(.orange)
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateScore = true
            }
        }
        .sheet(isPresented: $showDetails) {
            WrongAnswerListView(
                questions: viewModel.questions,
                wrongIDs: Set(viewModel.getAnswerResults.enumerated().compactMap { index, isCorrect in
                    isCorrect ? nil : viewModel.questions[index].id
                })
            )
        }
    }
}

// MARK: - スコアサークル
struct ScoreCircleView: View {
    let score: Double
    let correct: Int
    let total: Int
    let animate: Bool
    
    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景円
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 16)
                    .frame(width: 160, height: 160)
                
                // スコア円
                Circle()
                    .trim(from: 0, to: animate ? score / 100 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [scoreColor, scoreColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: animate)
                
                // 数値表示
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", score))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    Text("点")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(correct) / \(total) 問正解")
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - 統計カード
struct StatsCardView: View {
    let correctCount: Int
    let totalQuestions: Int
    let timeSpent: String
    let wrongCount: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ResultStatItem(
                value: "\(correctCount)",
                label: "正解",
                color: .green,
                icon: "checkmark.circle.fill"
            )
            
            Divider().frame(height: 50)
            
            ResultStatItem(
                value: "\(wrongCount)",
                label: "不正解",
                color: .red,
                icon: "xmark.circle.fill"
            )
            
            Divider().frame(height: 50)
            
            ResultStatItem(
                value: timeSpent,
                label: "所要時間",
                color: .blue,
                icon: "clock.fill"
            )
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct ResultStatItem: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 間違えた問題一覧
struct WrongAnswerListView: View {
    let questions: [Question]
    let wrongIDs: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    
    var wrongQuestions: [Question] {
        questions.filter { wrongIDs.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(wrongQuestions) { question in
                    WrongQuestionRow(question: question)
                }
            }
            .navigationTitle("間違えた問題")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct WrongQuestionRow: View {
    let question: Question
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(question.text.prefix(50) + (question.text.count > 50 ? "..." : ""))
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text("正解: \(question.options[question.correctAnswerIndex])")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    Text(question.explanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(.leading, 28)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let vm = QuizViewModel(questionSet: SampleData.part5Beginner)
    ResultView(viewModel: vm) {}
}
