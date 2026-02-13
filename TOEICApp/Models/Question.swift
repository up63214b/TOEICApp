// Question.swift
// TOEICApp - データモデル定義

import Foundation

// MARK: - 問題モデル
struct Question: Identifiable, Codable {
    let id: UUID
    let text: String           // 問題文
    let options: [String]      // 選択肢（A, B, C, D）
    let correctAnswerIndex: Int // 正解のインデックス（0〜3）
    let explanation: String    // 解説
    let part: TOEICPart        // TOEICのパート番号

    init(id: UUID = UUID(), text: String, options: [String],
         correctAnswerIndex: Int, explanation: String, part: TOEICPart = .part5) {
        self.id = id
        self.text = text
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
        self.part = part
    }
}

// MARK: - TOEICパート定義
enum TOEICPart: String, Codable, CaseIterable {
    case part5 = "Part 5"
    case part6 = "Part 6"
    case part7 = "Part 7"

    var description: String {
        switch self {
        case .part5: return "短文穴埋め問題"
        case .part6: return "長文穴埋め問題"
        case .part7: return "読解問題"
        }
    }

    var icon: String {
        switch self {
        case .part5: return "pencil.circle.fill"
        case .part6: return "doc.text.fill"
        case .part7: return "book.fill"
        }
    }
}

// MARK: - 問題セットモデル
struct QuestionSet: Identifiable, Codable {
    let id: UUID
    let title: String
    let part: TOEICPart
    let questions: [Question]
    let difficultyLevel: DifficultyLevel

    init(id: UUID = UUID(), title: String, part: TOEICPart,
         questions: [Question], difficultyLevel: DifficultyLevel = .beginner) {
        self.id = id
        self.title = title
        self.part = part
        self.questions = questions
        self.difficultyLevel = difficultyLevel
    }

    var questionCount: Int { questions.count }
}

// MARK: - 難易度
enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "初級"
    case intermediate = "中級"
    case advanced = "上級"

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}

// MARK: - 学習履歴モデル
struct StudyHistory: Identifiable, Codable {
    let id: UUID
    let date: Date
    let questionSetTitle: String
    let totalQuestions: Int
    let correctAnswers: Int
    let timeSpent: TimeInterval // 秒数

    init(id: UUID = UUID(), date: Date = Date(), questionSetTitle: String,
         totalQuestions: Int, correctAnswers: Int, timeSpent: TimeInterval) {
        self.id = id
        self.date = date
        self.questionSetTitle = questionSetTitle
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.timeSpent = timeSpent
    }

    var scorePercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }

    var formattedScore: String {
        return "\(correctAnswers) / \(totalQuestions)"
    }

    var formattedTimeSpent: String {
        let minutes = Int(timeSpent) / 60
        let seconds = Int(timeSpent) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 回答状態
enum AnswerState {
    case unanswered               // 未回答
    case answered(index: Int)     // 回答済み（インデックス付き）

    var isAnswered: Bool {
        if case .answered = self { return true }
        return false
    }

    var selectedIndex: Int? {
        if case .answered(let index) = self { return index }
        return nil
    }
}
