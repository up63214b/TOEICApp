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
        case .answered, .scoring, .scored:
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
        // stopTimer() // MainActor isolation issue in deinit
    }

    // MARK: - 現在の問題情報

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
        sheet.answers.filter { $0.selectedOption != nil }.count
    }

    var progress: Double {
        Double(answeredCount) / 200.0
    }

    var progressText: String {
        "\(answeredCount) / 200"
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
        if currentQuestion < 200 {
            currentQuestion += 1
        }
    }

    func goPrevious() {
        if currentQuestion > 1 {
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

    func score() {
        sheet.status = .scored
    }

    // MARK: - タイマー

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.isTimerRunning = true // dummy to keep reference
                // SwiftData モデルの更新は自動的に反映される
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


// MARK: - グリッドセルの状態
enum AnswerCellStatus {
    case unanswered
    case current
    case answered
}
