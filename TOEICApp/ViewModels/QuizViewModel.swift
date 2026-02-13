// QuizViewModel.swift
// TOEICApp - クイズ画面のビジネスロジック

import Foundation
import Combine

// MARK: - クイズ進行管理 ViewModel
class QuizViewModel: ObservableObject {
    
    // MARK: - Published プロパティ（画面と連動）
    @Published var currentQuestionIndex: Int = 0
    @Published var answerState: AnswerState = .unanswered
    @Published var isQuizFinished: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var showExplanation: Bool = false
    
    // MARK: - 内部プロパティ
    private(set) var questions: [Question]
    private(set) var questionSetTitle: String
    private(set) var wrongAnswerIDs: [UUID] = []
    private(set) var correctCount: Int = 0
    private var answerResults: [Bool] = [] // 各問の正誤
    
    // タイマー
    private var timer: Timer?
    private var startTime: Date?
    
    private let dataManager = DataManager.shared
    
    // MARK: - 初期化
    init(questionSet: QuestionSet) {
        self.questions = questionSet.questions
        self.questionSetTitle = questionSet.title
        self.answerResults = Array(repeating: false, count: questionSet.questions.count)
        startTimer()
    }
    
    // 復習モード用初期化
    init(questions: [Question], title: String) {
        self.questions = questions
        self.questionSetTitle = title
        self.answerResults = Array(repeating: false, count: questions.count)
        startTimer()
    }
    
    // MARK: - 現在の問題
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var progressText: String {
        "\(currentQuestionIndex + 1) / \(questions.count)"
    }
    
    var totalQuestions: Int { questions.count }
    
    // MARK: - 回答処理
    func answer(with index: Int) {
        guard case .unanswered = answerState,
              let question = currentQuestion else { return }
        
        answerState = .answered(index: index)
        
        let isCorrect = index == question.correctAnswerIndex
        answerResults[currentQuestionIndex] = isCorrect
        
        if isCorrect {
            correctCount += 1
        } else {
            wrongAnswerIDs.append(question.id)
            dataManager.addWrongQuestion(question.id)
        }
        
        // 解説を少し遅れて表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showExplanation = true
        }
    }
    
    // MARK: - 次の問題へ
    func moveToNext() {
        showExplanation = false
        
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            answerState = .unanswered
        } else {
            finishQuiz()
        }
    }
    
    // MARK: - クイズ終了処理
    private func finishQuiz() {
        stopTimer()
        isQuizFinished = true
        saveHistory()
    }
    
    private func saveHistory() {
        let history = StudyHistory(
            questionSetTitle: questionSetTitle,
            totalQuestions: questions.count,
            correctAnswers: correctCount,
            timeSpent: TimeInterval(elapsedSeconds)
        )
        dataManager.saveHistory(history)
    }
    
    // MARK: - タイマー制御
    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - 結果データ
    var scorePercentage: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(correctCount) / Double(questions.count) * 100
    }
    
    var resultMessage: String {
        switch scorePercentage {
        case 90...100: return "素晴らしい！完璧に近いスコアです！🎉"
        case 70..<90:  return "よくできました！もう少しで満点です！✨"
        case 50..<70:  return "もう一息！復習して再挑戦しましょう！💪"
        default:        return "基礎から復習しましょう。必ず上達します！📚"
        }
    }
    
    var getAnswerResults: [Bool] { answerResults }
    
    deinit {
        stopTimer()
    }
}
