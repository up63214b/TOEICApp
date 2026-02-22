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
    var status: Status {
        didSet {
            statusRaw = status.rawValue
        }
    }
    var statusRaw: Int
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
        self.statusRaw = Status.answering.rawValue
        self.inputOrder = inputOrder
        self.answers = (1...TOEICTemplate.totalQuestions).map { Answer(questionNumber: $0) }
    }
    
    // MARK: - 計算プロパティ
    var scorePercentage: Double {
        guard status == .scored else { return 0.0 }
        let answered = answers.filter { $0.selectedOption != nil && $0.correctOption != nil }.count
        guard answered > 0 else { return 0.0 }
        return Double(totalCorrect) / Double(answered) * 100
    }

    var answeredCount: Int {
        answers.filter { $0.selectedOption != nil }.count
    }
    
    var correctAnswersEnteredCount: Int {
        answers.filter { $0.correctOption != nil }.count
    }
    
    var totalCorrect: Int {
        answers.filter { $0.isCorrect }.count
    }
    
    var wrongAnswers: [WrongAnswer] {
        answers.compactMap { ans in
            // 両方入力済みで、かつ間違っている場合のみ「間違い」とする
            if let selected = ans.selectedOption, let correct = ans.correctOption, selected != correct {
                return WrongAnswer(
                    questionNumber: ans.questionNumber,
                    selectedOption: selected,
                    correctOption: correct,
                    note: ans.note
                )
            }
            return nil
        }
    }
    
    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var partScores: [PartScore] {
        TOEICPart.allCases.map { part in
            let range = TOEICTemplate.range(for: part)
            let partAnswers = answers.filter { range.contains($0.questionNumber) }
            let correctCount = partAnswers.filter { $0.isCorrect == true }.count
            return PartScore(part: part, correct: correctCount, total: partAnswers.count)
        }
    }
    
    var listeningPartScore: PartScore {
        let range = 1...100
        let partAnswers = answers.filter { range.contains($0.questionNumber) }
        let correctCount = partAnswers.filter { $0.isCorrect == true }.count
        return PartScore(part: .part1, correct: correctCount, total: 100)
    }
    
    var readingPartScore: PartScore {
        let range = 101...200
        let partAnswers = answers.filter { range.contains($0.questionNumber) }
        let correctCount = partAnswers.filter { $0.isCorrect == true }.count
        return PartScore(part: .part5, correct: correctCount, total: 100)
    }

    // MARK: - メソッド
    func setAnswer(_ option: String, for questionNumber: Int) {
        let index = questionNumber - 1
        guard index >= 0, index < answers.count else { return }
        answers[index].selectedOption = option
    }

    func clearAnswer(for questionNumber: Int) {
        let index = questionNumber - 1
        guard index >= 0, index < answers.count else { return }
        answers[index].selectedOption = nil
    }
    
    func setCorrectAnswer(_ option: String, for questionNumber: Int) {
        let index = questionNumber - 1
        guard index >= 0, index < answers.count else { return }
        answers[index].correctOption = option 
    }
}

// MARK: - Nested Types
extension AnswerSheet {
    enum Status: Int, Codable, CaseIterable {
        case answering, answered, scoring, scored, correctInput, correctReady
        
        var label: String {
            switch self {
            case .answering: return "解答中"
            case .answered: return "回答完了"
            case .scoring: return "採点中"
            case .scored: return "採点完了"
            case .correctInput: return "正解入力中"
            case .correctReady: return "正解入力済"
            }
        }
    }

    struct Answer: Codable, Identifiable, Hashable {
        var id: Int { questionNumber }
        let questionNumber: Int
        var selectedOption: String? // ユーザーの回答
        var correctOption: String?  // 正解データ
        var note: String?
        
        var isCorrect: Bool {
            guard let selected = selectedOption, let correct = correctOption else { return false }
            return selected == correct
        }
    }
}

// MARK: - Supporting Types
struct TOEICTemplate {
    static let totalQuestions = 200
    
    // Part 3/4 複数表示設定
    static let multiQuestionRange = 32...100
    static let questionsPerPage = 3
    
    static let partRanges: [(part: TOEICPart, range: ClosedRange<Int>)] = [
        (.part1, 1...6), (.part2, 7...31), (.part3, 32...70), (.part4, 71...100),
        (.part5, 101...130), (.part6, 131...146), (.part7, 147...200)
    ]
    
    static func range(for part: TOEICPart) -> ClosedRange<Int> {
        partRanges.first(where: { $0.part == part })?.range ?? 1...6
    }
    
    static func part(for q: Int) -> TOEICPart {
        partRanges.first(where: { $0.range.contains(q) })?.part ?? .part1
    }
    
    static func choiceLabels(for q: Int) -> [String] {
        part(for: q) == .part2 ? ["A", "B", "C"] : ["A", "B", "C", "D"]
    }
}

enum InputOrder: Int, Codable, CaseIterable {
    case answerFirst, correctFirst
}

struct PartScore: Codable, Identifiable {
    var id: Int { part.rawValue }
    let part: TOEICPart
    let correct: Int
    let total: Int
    var percentage: Double { total == 0 ? 0 : Double(correct) / Double(total) * 100 }
}

struct WrongAnswer: Codable, Identifiable {
    var id: Int { questionNumber }
    let questionNumber: Int
    let selectedOption: String?
    let correctOption: String?
    let note: String?
    
    var part: TOEICPart { TOEICTemplate.part(for: questionNumber) }
    var userAnswer: String? { selectedOption }
    var correctAnswer: String { correctOption ?? "?" }
}

enum TOEICPart: Int, CaseIterable, Identifiable, Codable {
    case part1 = 1, part2, part3, part4, part5, part6, part7
    var id: Int { rawValue }
    var name: String { "Part \(rawValue)" }
    var description: String { "Part \(rawValue)" }
    
    var isListening: Bool { rawValue <= 4 }
    var icon: String {
        switch self {
        case .part1: return "camera"
        case .part2: return "bubble.left.and.bubble.right"
        case .part3: return "person.2"
        case .part4: return "megaphone"
        case .part5: return "text.cursor"
        case .part6: return "doc.text"
        case .part7: return "doc.plaintext"
        }
    }
}
