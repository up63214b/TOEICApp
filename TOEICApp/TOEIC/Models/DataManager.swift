// DataManager.swift
// TOEICApp - データ永続化管理（UserDefaults使用）

import Foundation
import Combine

// MARK: - データ管理クラス
// @MainActor: @Published プロパティの更新を必ずメインスレッドで行うことを保証する（#3対応）
@MainActor
class DataManager: ObservableObject {

    static let shared = DataManager()

    // MARK: - Published プロパティ
    @Published var sheets: [AnswerSheet] = []

    // MARK: - UserDefaults キー
    private let sheetsKey = "answer_sheets"

    private init() {
        loadSheets()
    }

    // MARK: - 解答シートの保存・読み込み

    func addSheet(_ sheet: AnswerSheet) {
        sheets.insert(sheet, at: 0)
        saveSheets()
    }

    func updateSheet(_ sheet: AnswerSheet) {
        if let index = sheets.firstIndex(where: { $0.id == sheet.id }) {
            sheets[index] = sheet
            saveSheets()
        }
    }

    func deleteSheet(_ sheet: AnswerSheet) {
        sheets.removeAll { $0.id == sheet.id }
        saveSheets()
    }

    func clearAllSheets() {
        sheets = []
        UserDefaults.standard.removeObject(forKey: sheetsKey)
    }

    private func saveSheets() {
        if let encoded = try? JSONEncoder().encode(sheets) {
            UserDefaults.standard.set(encoded, forKey: sheetsKey)
        }
    }

    private func loadSheets() {
        if let data = UserDefaults.standard.data(forKey: sheetsKey),
           let decoded = try? JSONDecoder().decode([AnswerSheet].self, from: data) {
            sheets = decoded
        }
    }

    // MARK: - フィルタリング

    /// 進行中のシート（answering / answered / scoring）
    var activeSheets: [AnswerSheet] {
        sheets.filter { $0.status != .scored }
    }

    /// 採点済みのシート
    var scoredSheets: [AnswerSheet] {
        sheets.filter { $0.status == .scored }
    }

    // MARK: - 統計情報

    var totalSheets: Int {
        sheets.count
    }

    var totalScoredSheets: Int {
        scoredSheets.count
    }

    var averageScore: Double {
        let scored = scoredSheets
        guard !scored.isEmpty else { return 0 }
        let total = scored.reduce(0.0) { $0 + $1.scorePercentage }
        return total / Double(scored.count)
    }
}
