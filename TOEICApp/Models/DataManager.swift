// DataManager.swift
// TOEICApp - データ永続化管理（UserDefaults使用）

import Foundation
import Combine

// MARK: - データ管理クラス
class DataManager: ObservableObject {
    
    static let shared = DataManager()
    
    // MARK: - Published プロパティ
    @Published var studyHistory: [StudyHistory] = []
    @Published var wrongQuestionIDs: Set<UUID> = []
    
    // MARK: - UserDefaults キー
    private let historyKey = "study_history"
    private let wrongQuestionsKey = "wrong_questions"
    
    private init() {
        loadHistory()
        loadWrongQuestions()
    }
    
    // MARK: - 学習履歴の保存・読み込み
    
    func saveHistory(_ history: StudyHistory) {
        studyHistory.insert(history, at: 0) // 最新が先頭
        saveHistoryToStorage()
    }
    
    private func saveHistoryToStorage() {
        if let encoded = try? JSONEncoder().encode(studyHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([StudyHistory].self, from: data) {
            studyHistory = decoded
        }
    }
    
    func clearHistory() {
        studyHistory = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    // MARK: - 間違えた問題の管理
    
    func addWrongQuestion(_ id: UUID) {
        wrongQuestionIDs.insert(id)
        saveWrongQuestions()
    }
    
    func removeWrongQuestion(_ id: UUID) {
        wrongQuestionIDs.remove(id)
        saveWrongQuestions()
    }
    
    func clearWrongQuestions() {
        wrongQuestionIDs = []
        UserDefaults.standard.removeObject(forKey: wrongQuestionsKey)
    }
    
    private func saveWrongQuestions() {
        let idStrings = wrongQuestionIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: wrongQuestionsKey)
    }
    
    private func loadWrongQuestions() {
        if let idStrings = UserDefaults.standard.stringArray(forKey: wrongQuestionsKey) {
            wrongQuestionIDs = Set(idStrings.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - 統計情報
    
    var totalStudySessions: Int {
        studyHistory.count
    }
    
    var averageScore: Double {
        guard !studyHistory.isEmpty else { return 0 }
        let total = studyHistory.reduce(0.0) { $0 + $1.scorePercentage }
        return total / Double(studyHistory.count)
    }
    
    var totalQuestionsAnswered: Int {
        studyHistory.reduce(0) { $0 + $1.totalQuestions }
    }
    
    var wrongQuestionsCount: Int {
        wrongQuestionIDs.count
    }
}
