// AnswerSheetViewModel.swift
// TOEICApp - 解答シートのビジネスロジック

import Foundation
import Combine
import SwiftData

// MARK: - 入力モード
enum InputMode {
    case answer   // ユーザー回答入力
    case correct  // 正解入力
}

// MARK: - ViewModel
@MainActor
class AnswerSheetViewModel: ObservableObject, Identifiable {

    @Published var sheet: AnswerSheet
    @Published var currentQuestion: Int = 1
    @Published var inputMode: InputMode = .answer
    @Published var isTimerRunning: Bool = false
    @Published var showGrid: Bool = false
    
    // 表示問題数の設定 (1, 3, 5, 10など)
    @Published var questionsPerPage: Int = 3
    
    // 現在のモードに応じた実質的な表示数
    var effectiveQuestionsPerPage: Int {
        // .correctモード（正解入力時）は10問ずつ、それ以外はユーザー設定に従う
        inputMode == .correct ? 10 : questionsPerPage
    }

    private var timer: Timer?

    init(sheet: AnswerSheet) {
        self.sheet = sheet

        // モードを状態から推定
        switch sheet.status {
        case .answering:
            inputMode = .answer
        case .answered, .scoring, .scored, .correctInput, .correctReady:
            inputMode = .correct
        }

        // 入力モードに応じて最初の未入力問題へ移動
        if inputMode == .answer {
            moveToFirstUnanswered()
        } else {
            moveToFirstUnansweredCorrect()
        }
    }

    deinit {
        // Timer should be stopped by the View (onDisappear) to ensure main thread safety.
        // stopTimer() cannot be called here due to MainActor isolation.
        timer?.invalidate()
    }

    // MARK: - 現在の問題情報

    var currentQuestionRange: ClosedRange<Int> {
        let perPage = effectiveQuestionsPerPage
        if perPage > 1 {
            let offset = (currentQuestion - 1) / perPage
            let start = (offset * perPage) + 1
            let end = min(start + perPage - 1, TOEICTemplate.totalQuestions)
            return start...end
        } else {
            return currentQuestion...currentQuestion
        }
    }

    var currentPart: TOEICPart {
        TOEICTemplate.part(for: currentQuestion)
    }

    var choiceLabels: [String] {
        TOEICTemplate.choiceLabels(for: currentQuestion)
    }

    var currentAnswer: String? {
        let index = currentQuestion - 1
        guard index < sheet.answers.count else { return nil }
        
        switch inputMode {
        case .answer:
            return sheet.answers[index].selectedOption
        case .correct:
            return sheet.answers[index].correctOption
        }
    }

    var answeredCount: Int {
        sheet.answeredCount
    }

    var progress: Double {
        Double(answeredCount) / Double(TOEICTemplate.totalQuestions)
    }

    var progressText: String {
        "\(answeredCount) / \(TOEICTemplate.totalQuestions)"
    }

    // MARK: - 回答操作

    func selectChoice(_ choice: String) {
        let index = currentQuestion - 1
        guard index < sheet.answers.count else { return }
        
        switch inputMode {
        case .answer:
            sheet.setAnswer(choice, for: currentQuestion)
            sheet.status = .answering
        case .correct:
            sheet.setCorrectAnswer(choice, for: currentQuestion)
            // 採点中ステータスにする（必要に応じて）
            if sheet.status != .scored {
                sheet.status = .scoring
            }
        }
        
        // 複数問題表示の場合の自動遷移ロジック
        if effectiveQuestionsPerPage > 1 {
            let range = currentQuestionRange
            // ページ内の全問題が回答済みかチェック
            let allAnswered = range.allSatisfy { q in
                sheet.answers[q-1].selectedOption != nil
            }
            
            if allAnswered && range.upperBound < TOEICTemplate.totalQuestions {
                // 全て解き終わったら次のページへ
                currentQuestion = range.upperBound + 1
            } else {
                // ページ内にとどまる。フォーカスは現在の問題のまま（自動で動かさないことで順不同入力をしやすくする）
            }
        } else {
            // 単一問題表示の場合の自動遷移
            if currentQuestion < TOEICTemplate.totalQuestions {
                goNext()
            }
        }
    }

    func clearCurrentAnswer() {
        let index = currentQuestion - 1
        guard index < sheet.answers.count else { return }
        sheet.answers[index].selectedOption = nil
    }

    // MARK: - ナビゲーション

    func goToQuestion(_ number: Int) {
        guard number >= 1, number <= 200 else { return }
        currentQuestion = number
    }

    func goNext() {
        if effectiveQuestionsPerPage > 1 {
            let next = currentQuestionRange.upperBound + 1
            currentQuestion = min(next, TOEICTemplate.totalQuestions)
        } else if currentQuestion < TOEICTemplate.totalQuestions {
            currentQuestion += 1
        }
    }

    func goPrevious() {
        if effectiveQuestionsPerPage > 1 {
            let prev = currentQuestionRange.lowerBound - effectiveQuestionsPerPage
            currentQuestion = max(prev, 1)
        } else if currentQuestion > 1 {
            currentQuestion -= 1
        }
    }

    func moveToFirstUnanswered() {
        if let index = sheet.answers.firstIndex(where: { $0.selectedOption == nil }) {
            currentQuestion = index + 1
        }
    }

    func moveToFirstUnansweredCorrect() {
        // 正解入力のロジックは Answer 構造体の拡張が必要
        if let index = sheet.answers.firstIndex(where: { $0.selectedOption == nil }) {
            currentQuestion = index + 1
        }
    }

    // MARK: - ステータス遷移

    func finishAnswering() {
        stopTimer()
        sheet.status = .answered
    }

    func startCorrectInput() {
        inputMode = .correct
        sheet.status = .scoring
        currentQuestion = 1
    }


    func saveToStorage() {
        // SwiftData does this automatically for reference types
    }
    
    func finishCorrectInput() {
        sheet.status = .correctReady
    }

    func score() {
        sheet.status = .scored
    }

    // MARK: - タイマー

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // クラスが @MainActor なので、メインスレッドでの実行を保証
            Task { @MainActor in
                self.sheet.elapsedSeconds += 1
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    // MARK: - グリッド用ヘルパー

    func answerStatus(for questionNumber: Int) -> AnswerCellStatus {
        let index = questionNumber - 1
        guard index < sheet.answers.count else { return .unanswered }
        
        if sheet.answers[index].selectedOption != nil {
            return .answered
        }
        return questionNumber == currentQuestion ? .current : .unanswered
    }
}

// MARK: - グリッドセルの状態
enum AnswerCellStatus {
    case unanswered
    case current
    case answered
}
