// AnswerSheet.swift
// TOEICApp - 解答シートモデル (SwiftData対応)

import Foundation
import SwiftData

@Model
final class AnswerSheet {
    // SwiftDataが主キーとして利用するユニークなID
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var status: Status
    
    // @Relationshipを使用してリレーションを定義することも可能
    var answers: [Answer]
    
    var listeningScore: Int?
    var readingScore: Int?

    init(title: String, createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.status = .answering
        // TOEICは200問なので、空の解答で初期化
        self.answers = (1...200).map { Answer(questionNumber: $0) }
    }
    
    // DataManagerにあった計算プロパティをモデル内に配置
    var scorePercentage: Double {
        guard status == .scored, let listening = listeningScore, let reading = readingScore else { return 0.0 }
        let totalScore = listening + reading
        // 満点は990点
        return Double(totalScore) / 990.0
    }
}

// MARK: - Nested Types
// SwiftDataモデルに含めるカスタム型はCodableに準拠させる
extension AnswerSheet {
    enum Status: Int, Codable, CaseIterable {
        case answering // 解答中
        case answered  // 解答完了
        case scoring   // 採点中
        case scored    // 採点完了
    }

    struct Answer: Codable, Identifiable, Hashable {
        var id: Int { questionNumber }
        let questionNumber: Int
        var selectedOption: String? // "A", "B", "C", "D"など
        var isCorrect: Bool?
    }
}

// MARK: - TOEIC パート定義（全7パート）
// この定義はデータ永続化とは直接関係ないため、そのまま残す
enum TOEICPart: Int, CaseIterable, Identifiable {
    case part1 = 1, part2, part3, part4, part5, part6, part7

    var id: Int { rawValue }

    var name: String {
        "Part \(rawValue)"
    }
}