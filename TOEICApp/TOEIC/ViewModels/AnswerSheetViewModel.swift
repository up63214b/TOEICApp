// AnswerSheetViewModel.swift
// TOEICApp - 解答シートのビジネスロジック

import Foundation
import Combine

// MARK: - 入力モード
enum InputMode {
    case answer   // ユーザー回答入力
    case correct  // 正解入力
}

// MARK: - ViewModel
class AnswerSheetViewModel: ObservableObject {

    @Published var sheet: AnswerSheet
    @Published var currentQuestion: Int = 1
    @Published var inputMode: InputMode = .answer
    @Published var isTimerRunning: Bool = false
    @Published var showGrid: Bool = false

    private var timer: Timer?
    private weak var dataManager: DataManager?

    init(sheet: AnswerSheet, dataManager: DataManager) {
        self.sheet = sheet
        self.dataManager = dataManager

        // モードを状態から推定
        switch sheet.status {
        case .answering:
            inputMode = .answer
        case .answered, .scoring:
            inputMode = .correct
        case .scored:
            inputMode = .correct
        }

        // 回答入力中なら未回答の最初の問題へ移動
        if inputMode == .answer {
            moveToFirstUnanswered()
        } else {
            moveToFirstUnansweredCorrect()
        }
    }

    deinit {
        stopTimer()
    }

    // MARK: - 現在の問題情報

    var currentPart: TOEICPart {
        TOEICTemplate.part(for: currentQuestion)
    }

    var choiceLabels: [String] {
        TOEICTemplate.choiceLabels(for: currentQuestion)
    }

    var currentAnswer: String? {
        switch inputMode {
        case .answer:
            return sheet.userAnswers[currentQuestion - 1]
        case .correct:
            return sheet.correctAnswers[currentQuestion - 1]
        }
    }

    var progress: Double {
        switch inputMode {
        case .answer:
            return Double(sheet.answeredCount) / Double(TOEICTemplate.totalQuestions)
        case .correct:
            return Double(sheet.correctAnswersEnteredCount) / Double(TOEICTemplate.totalQuestions)
        }
    }

    var progressText: String {
        switch inputMode {
        case .answer:
            return "\(sheet.answeredCount) / \(TOEICTemplate.totalQuestions)"
        case .correct:
            return "\(sheet.correctAnswersEnteredCount) / \(TOEICTemplate.totalQuestions)"
        }
    }

    // MARK: - 回答操作

    func selectChoice(_ choice: String) {
        switch inputMode {
        case .answer:
            sheet.setAnswer(choice, for: currentQuestion)
            sheet.status = .answering
        case .correct:
            sheet.setCorrectAnswer(choice, for: currentQuestion)
            sheet.status = .scoring
        }
        // save()は呼ばない（親ビューの再描画でfullScreenCoverが閉じるのを防ぐ）
    }

    func clearCurrentAnswer() {
        switch inputMode {
        case .answer:
            sheet.clearAnswer(for: currentQuestion)
        case .correct:
            sheet.correctAnswers[currentQuestion - 1] = nil
        }
    }

    // MARK: - ナビゲーション

    func goToQuestion(_ number: Int) {
        guard number >= 1, number <= TOEICTemplate.totalQuestions else { return }
        currentQuestion = number
    }

    func goNext() {
        if currentQuestion < TOEICTemplate.totalQuestions {
            currentQuestion += 1
        }
    }

    func goPrevious() {
        if currentQuestion > 1 {
            currentQuestion -= 1
        }
    }

    func moveToFirstUnanswered() {
        if let index = sheet.userAnswers.firstIndex(where: { $0 == nil }) {
            currentQuestion = index + 1
        }
    }

    func moveToFirstUnansweredCorrect() {
        if let index = sheet.correctAnswers.firstIndex(where: { $0 == nil }) {
            currentQuestion = index + 1
        }
    }

    // MARK: - ステータス遷移

    /// 回答完了にする
    func finishAnswering() {
        sheet.status = .answered
        stopTimer()
        save()
    }

    /// 正解入力モードに切り替え
    func startCorrectInput() {
        inputMode = .correct
        sheet.status = .scoring
        currentQuestion = 1
        moveToFirstUnansweredCorrect()
        save()
    }

    /// 採点実行
    func score() {
        sheet.status = .scored
        save()
    }

    /// 回答入力に戻る
    func resumeAnswering() {
        inputMode = .answer
        sheet.status = .answering
        currentQuestion = 1
        moveToFirstUnanswered()
        save()
    }

    // MARK: - タイマー

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
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

    // MARK: - 永続化

    /// 画面を閉じるときに呼ぶ（DataManagerに一括保存）
    func saveToStorage() {
        dataManager?.updateSheet(sheet)
    }

    private func save() {
        dataManager?.updateSheet(sheet)
    }

    // MARK: - グリッド用ヘルパー

    /// 問題番号の回答状態を返す（グリッド表示用）
    func answerStatus(for questionNumber: Int) -> AnswerCellStatus {
        let index = questionNumber - 1
        switch inputMode {
        case .answer:
            if sheet.userAnswers[index] != nil {
                return .answered
            }
            return questionNumber == currentQuestion ? .current : .unanswered
        case .correct:
            if sheet.correctAnswers[index] != nil {
                return .answered
            }
            return questionNumber == currentQuestion ? .current : .unanswered
        }
    }
}

// MARK: - グリッドセルの状態
enum AnswerCellStatus {
    case unanswered
    case current
    case answered
}
