// AnswerSheet.swift
// TOEICApp - 解答シートモデル (SwiftData対応)

import Foundation
import SwiftData
import SwiftUI

@Model
final class AnswerSheet {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var status: Status
    var inputOrder: InputOrder
    var answers: [Answer]
    var listeningScore: Int?
    var readingScore: Int?
    var elapsedSeconds: Int = 0

    init(title: String, inputOrder: InputOrder = .answerFirst, createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.status = .answering
        self.inputOrder = inputOrder
        self.answers = (1...TOEICTemplate.totalQuestions).map { Answer(questionNumber: $0) }
    }
    
    // MARK: - 計算プロパティ
    var scorePercentage: Double {
        guard status == .scored, let listening = listeningScore, let reading = readingScore else { return 0.0 }
        let totalScore = listening + reading
        return Double(totalScore) / 990.0
    }

    var answeredCount: Int {
        answers.filter { $0.selectedOption != nil }.count
    }
    
    var totalCorrect: Int {
        answers.filter { $0.isCorrect == true }.count
    }
    
    var wrongAnswers: [WrongAnswer] {
        answers.compactMap { ans in
            if ans.isCorrect == false {
                return WrongAnswer(questionNumber: ans.questionNumber, selectedOption: ans.selectedOption, correctOption: "?")
            }
            return nil
        }
    }
    
    var formattedTime: String {
        let minutes = elapsedSeconds /