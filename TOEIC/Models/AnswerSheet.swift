// AnswerSheet.swift
// TOEICApp - 解答シートモデル

import Foundation

// MARK: - TOEIC パート定義（全7パート）
enum TOEICPart: Int, Codable, CaseIterable, Identifiable {
    case part1 = 1, part2, part3, part4, part5, part6, part7

    var id: Int { rawValue }

    var name: String {
        "Part \(rawValue)"
    }

    var description: String {
        switch self {
        case .part1: return "写真描写問題"
        case .part2: return "応答問題"
        case .part3: return "会話問題"
        case .part4: return "説明文問題"
        case .part5: return "短文穴埋め問題"
        case .part6: return "長文穴埋め問題"
        case .part7: return "読解問題"
        }
    }

    /// このパートの問題数
    var questionCount: Int {
        switch self {
        case .part1: return 6
        case .part2: return 25
        case .part3: return 39
        case .part4: return 30
        case .part5: return 30
        case .part6: return 16
        case .part7: return 54
        }
    }

    /// 選択肢の数（Part2のみ3択、他は4択）
    var choiceCount: Int {
        self == .part2 ? 3 : 4
    }

    /// 選択肢のラベル配列
    var choiceLabels: [String] {
        self == .part2 ? ["A", "B", "C"] : ["A", "B", "C", "D"]
    }

    /// リスニング / リーディング
    var isListening: Bool {
        switch self {
        case .part1, .part2, .part3, .part4: return true
        case .part5, .part6, .part7: return false
        }
    }

    var icon: String {
        isListening ? "headphones" : "doc.text"
    }
}

// MARK: - TOEIC テンプレート（全200問の構成）
struct TOEICTemplate {
    /// パートごとの問題範囲（1-indexed）
    static let partRanges: [(part: TOEICPart, range: ClosedRange<Int>)] = {
        var ranges: [(TOEICPart, ClosedRange<Int>)] = []
        var start = 1
        for part in TOEICPart.allCases {
            let end = start + part.questionCount - 1
            ranges.append((part, start...end))
            start = end + 1
        }
        return ranges
    }()

    static let totalQuestions = 200

    /// 問題番号からパートを取得
    static func part(for questionNumber: Int) -> TOEICPart {
        for (part, range) in partRanges {
            if range.contains(questionNumber) {
                return part
            }
        }
        return .part7 // fallback
    }

    /// 問題番号の選択肢数を取得
    static func choiceCount(for questionNumber: Int) -> Int {
        part(for: questionNumber).choiceCount
    }

    /// 問題番号の選択肢ラベルを取得
    static func choiceLabels(for questionNumber: Int) -> [String] {
        part(for: questionNumber).choiceLabels
    }
}

// MARK: - 解答シートのステータス
enum SheetStatus: String, Codable {
    case answering    // 回答入力中
    case answered     // 回答完了（正解未入力）
    case scoring      // 正解入力中
    case scored       // 採点完了

    var label: String {
        switch self {
        case .answering: return "回答中"
        case .answered:  return "回答完了"
        case .scoring:   return "採点中"
        case .scored:    return "採点済み"
        }
    }

    var color: String {
        switch self {
        case .answering: return "blue"
        case .answered:  return "orange"
        case .scoring:   return "purple"
        case .scored:    return "green"
        }
    }
}

// MARK: - パート別スコア
struct PartScore: Codable, Identifiable {
    var id: Int { part.rawValue }
    let part: TOEICPart
    let correct: Int
    let total: Int

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}

// MARK: - 解答シート
struct AnswerSheet: Identifiable, Codable {
    let id: UUID
    var title: String
    var createdAt: Date
    var status: SheetStatus

    /// ユーザーの回答（1〜200、nilは未回答）
    var userAnswers: [String?]

    /// 正解データ（1〜200、nilは未入力）
    var correctAnswers: [String?]

    /// タイマー経過秒数
    var elapsedSeconds: Int

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.status = .answering
        self.userAnswers = Array(repeating: nil, count: TOEICTemplate.totalQuestions)
        self.correctAnswers = Array(repeating: nil, count: TOEICTemplate.totalQuestions)
        self.elapsedSeconds = 0
    }

    // MARK: - 回答操作

    /// 問題番号(1-indexed)に回答をセット
    mutating func setAnswer(_ answer: String, for questionNumber: Int) {
        guard questionNumber >= 1, questionNumber <= TOEICTemplate.totalQuestions else { return }
        userAnswers[questionNumber - 1] = answer
    }

    /// 問題番号(1-indexed)の回答をクリア
    mutating func clearAnswer(for questionNumber: Int) {
        guard questionNumber >= 1, questionNumber <= TOEICTemplate.totalQuestions else { return }
        userAnswers[questionNumber - 1] = nil
    }

    /// 問題番号(1-indexed)に正解をセット
    mutating func setCorrectAnswer(_ answer: String, for questionNumber: Int) {
        guard questionNumber >= 1, questionNumber <= TOEICTemplate.totalQuestions else { return }
        correctAnswers[questionNumber - 1] = answer
    }

    // MARK: - 集計

    /// 回答済み問題数
    var answeredCount: Int {
        userAnswers.compactMap { $0 }.count
    }

    /// 正解入力済み問題数
    var correctAnswersEnteredCount: Int {
        correctAnswers.compactMap { $0 }.count
    }

    /// 全問回答済みか
    var isFullyAnswered: Bool {
        answeredCount == TOEICTemplate.totalQuestions
    }

    /// 全問正解入力済みか
    var isFullyCorrectAnswered: Bool {
        correctAnswersEnteredCount == TOEICTemplate.totalQuestions
    }

    // MARK: - 採点

    /// 正解数（全体）
    var totalCorrect: Int {
        var count = 0
        for i in 0..<TOEICTemplate.totalQuestions {
            if let user = userAnswers[i], let correct = correctAnswers[i], user == correct {
                count += 1
            }
        }
        return count
    }

    /// 正解率（全体）
    var scorePercentage: Double {
        Double(totalCorrect) / Double(TOEICTemplate.totalQuestions) * 100
    }

    /// パート別スコア
    var partScores: [PartScore] {
        TOEICTemplate.partRanges.map { part, range in
            var correct = 0
            var total = 0
            for q in range {
                total += 1
                if let user = userAnswers[q - 1], let ans = correctAnswers[q - 1], user == ans {
                    correct += 1
                }
            }
            return PartScore(part: part, correct: correct, total: total)
        }
    }

    /// リスニングスコア
    var listeningScore: PartScore {
        let listeningParts = partScores.filter { $0.part.isListening }
        let correct = listeningParts.reduce(0) { $0 + $1.correct }
        let total = listeningParts.reduce(0) { $0 + $1.total }
        return PartScore(part: .part1, correct: correct, total: total)
    }

    /// リーディングスコア
    var readingScore: PartScore {
        let readingParts = partScores.filter { !$0.part.isListening }
        let correct = readingParts.reduce(0) { $0 + $1.correct }
        let total = readingParts.reduce(0) { $0 + $1.total }
        return PartScore(part: .part5, correct: correct, total: total)
    }

    /// 経過時間フォーマット
    var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
