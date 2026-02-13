// ReviewView.swift
// TOEICApp - 復習画面（Phase 6）

import SwiftUI

struct ReviewView: View {
    
    @EnvironmentObject var dataManager: DataManager
    @State private var showQuiz = false
    
    // 全問題の中から間違えた問題を抽出
    var wrongQuestions: [Question] {
        let allQuestions = SampleData.allQuestionSets.flatMap { $0.questions }
        return allQuestions.filter { dataManager.wrongQuestionIDs.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if wrongQuestions.isEmpty {
                    EmptyReviewView()
                } else {
                    WrongQuestionsListView(
                        questions: wrongQuestions,
                        onStartReview: { showQuiz = true }
                    )
                }
            }
            .navigationTitle("復習")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showQuiz) {
                QuizContainerView(
                    questionSet: QuestionSet(
                        title: "復習モード",
                        part: .part5,
                        questions: wrongQuestions.shuffled()
                    )
                )
            }
        }
    }
}

// MARK: - 復習問題なし表示
struct EmptyReviewView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("要復習の問題はありません")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("問題集を解いて間違えた問題が\nここに表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - 復習問題リスト
struct WrongQuestionsListView: View {
    
    let questions: [Question]
    let onStartReview: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー（要復習件数）
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("要復習: \(questions.count)問")
                        .font(.headline)
                    Text("間違えた問題をもう一度解きましょう")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: onStartReview) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text("復習開始")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // 問題リスト
            List {
                ForEach(questions) { question in
                    ReviewQuestionRow(question: question)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        dataManager.removeWrongQuestion(questions[index].id)
                    }
                }
            }
            .listStyle(.grouped)
        }
    }
}

// MARK: - 復習問題行
struct ReviewQuestionRow: View {
    let question: Question
    @State private var showExplanation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                // パートバッジ
                Text(question.part.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                
                Text(question.text.prefix(60) + (question.text.count > 60 ? "..." : ""))
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            // 正解表示
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("正解: \(question.options[question.correctAnswerIndex])")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: { withAnimation { showExplanation.toggle() } }) {
                    Text(showExplanation ? "解説を閉じる" : "解説を見る")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // 解説
            if showExplanation {
                Text(question.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(10)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReviewView()
        .environmentObject(DataManager.shared)
}
