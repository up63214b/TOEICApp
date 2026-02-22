// AnswerSheet.swift
// TOEICApp - 解答シートモデル (SwiftData対応)

import Foundation
import SwiftData // SwiftDataをインポート

// MARK: - TOEIC パート定義（全7パート）
// Codable準拠は不要
enum TOEICPart: Int, CaseIterable, Identifiable {
    case part1 = 1, part2, part3, part4, part5, part6, part7

    var id: Int { rawValue }

    var name: String {
        "Part \(rawValue)"
    }

