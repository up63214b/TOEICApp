// HomeView.swift
// TOEICApp - ホーム画面（問題集一覧）

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedQuestionSet: QuestionSet?
    @State private var showQuiz = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // ヘッダーカード
                    HeaderCardView()
                        .padding(.horizontal)
                    
                    // 問題集セクション
                    VStack(alignment: .leading, spacing: 12) {
                        Text("問題集を選ぶ")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(SampleData.allQuestionSets) { questionSet in
                            QuestionSetCardView(questionSet: questionSet) {
                                selectedQuestionSet = questionSet
                                showQuiz = true
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("TOEIC学習アプリ")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showQuiz) {
                if let questionSet = selectedQuestionSet {
                    QuizContainerView(questionSet: questionSet)
                }
            }
        }
    }
}

// MARK: - ヘッダーカード
struct HeaderCardView: View {
    
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 0) {
            // グラデーション背景
            ZStack {
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                HStack(spacing: 20) {
                    // 統計1: 学習回数
                    StatItemView(
                        value: "\(dataManager.totalStudySessions)",
                        label: "学習回数",
                        icon: "checkmark.circle.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.5))
                    
                    // 統計2: 平均スコア
                    StatItemView(
                        value: String(format: "%.0f%%", dataManager.averageScore),
                        label: "平均スコア",
                        icon: "chart.bar.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.5))
                    
                    // 統計3: 要復習
                    StatItemView(
                        value: "\(dataManager.wrongQuestionsCount)",
                        label: "要復習",
                        icon: "exclamationmark.circle.fill"
                    )
                }
                .padding()
            }
        }
        .cornerRadius(16)
        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct StatItemView: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 問題集カード
struct QuestionSetCardView: View {
    
    let questionSet: QuestionSet
    let action: () -> Void
    
    var difficultyColor: Color {
        switch questionSet.difficultyLevel {
        case .beginner:     return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(difficultyColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: questionSet.part.icon)
                        .font(.title2)
                        .foregroundColor(difficultyColor)
                }
                
                // テキスト情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(questionSet.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(questionSet.part.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("·")
                            .foregroundColor(.secondary)
                        
                        Text(questionSet.part.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        // 難易度バッジ
                        Text(questionSet.difficultyLevel.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(difficultyColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(difficultyColor.opacity(0.15))
                            .cornerRadius(8)
                        
                        // 問題数バッジ
                        Text("\(questionSet.questionCount)問")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager.shared)
}
