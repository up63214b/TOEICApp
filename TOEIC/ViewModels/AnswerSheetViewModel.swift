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
        if TOEICTemplate.multiQuestionRange.contains(currentQuestion) {
            let startBase = TOEICTemplate.multiQuestionRange.lowerBound
            let offset = (currentQuestion - startBase) / TOEICTemplate.questionsPerPage
            let start = startBase + (offset * TOEICTemplate.questionsPerPage)
            let end = min(start + TOEICTemplate.questionsPerPage - 1, TOEICTemplate.multiQuestionRange.upperBound)
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
            // 注意: AnswerSheet.Answer 構造体に correctOption が追加されていない場合は
            // ここでモデルの拡張が必要になる可能性があるが、現状のモデルに合わせる
            return sheet.answers[index].selectedOption // 仮
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
            sheet.answers[index].selectedOption = choice
            sheet.status = .answering
        case .correct:
            sheet.answers[index].selectedOption = choice
            sheet.status = .scoring
        }
        
        // 複数問題表示（Q32-100）の場合の自動遷移ロジック
        if TOEICTemplate.multiQuestionRange.contains(currentQuestion) {
            let range = currentQuestionRange
            // ページ内の全問題が回答済みかチェック
            let allAnswered = range.allSatisfy { q in
                sheet.answers[q-1].selectedOption != nil
            }
            if allAnswered && range.upperBound < TOEICTemplate.totalQuestions {
                // 次のページ/問題へ
                currentQuestion = range.upperBound + 1
            } else if sheet.answers[currentQuestion-1].selectedOption != nil && currentQuestion < range.upperBound {
                // ページ内の次の問題へ
                currentQuestion += 1
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
        if (TOEICTemplate.multiQuestionRange.lowerBound...(TOEICTemplate.multiQuestionRange.upperBound - TOEICTemplate.questionsPerPage)).contains(currentQuestion) {
            // 3問スキップして次のグループの先頭へ
            let next = currentQuestionRange.upperBound + 1
            currentQuestion = min(next, TOEICTemplate.totalQuestions)
        } else if currentQuestion < TOEICTemplate.totalQuestions {
            currentQuestion += 1
        }
    }

    func goPrevious() {
        let multiStart = TOEICTemplate.multiQuestionRange.lowerBound
        let multiEnd = TOEICTemplate.multiQuestionRange.upperBound
        
        if ((multiStart + TOEICTemplate.questionsPerPage)...multiEnd).contains(currentQuestion) {
            // 3問戻って前のグループの先頭へ
            let prev = currentQuestionRange.lowerBound - TOEICTemplate.questionsPerPage
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
