// SampleData.swift
// TOEICApp - サンプル問題データ

import Foundation

// MARK: - サンプル問題データ
struct SampleData {

    // MARK: Part 5 問題セット1（初級）
    static let part5Beginner = QuestionSet(
        title: "Part 5 初級編 Vol.1",
        part: .part5,
        questions: [
            Question(
                text: "Mr. Tanaka _____ to the station yesterday.",
                options: ["go", "went", "gone", "going"],
                correctAnswerIndex: 1,
                explanation: "yesterday（昨日）という過去を示す副詞があるため、動詞は過去形にする必要があります。goの過去形はwentです。",
                part: .part5
            ),
            Question(
                text: "The report will be submitted _____ next Monday.",
                options: ["on", "by", "at", "in"],
                correctAnswerIndex: 1,
                explanation: "「〜までに」という期限を表す場合はbyを使います。onは特定の日付、atは時刻、inは期間に使います。",
                part: .part5
            ),
            Question(
                text: "She is _____ experienced engineer in our team.",
                options: ["a most", "the most", "more", "most"],
                correctAnswerIndex: 1,
                explanation: "最上級の形容詞の前には定冠詞theが必要です。「チームの中で最も経験豊富なエンジニア」という意味になります。",
                part: .part5
            ),
            Question(
                text: "The meeting was postponed _____ bad weather.",
                options: ["because", "due to", "since", "although"],
                correctAnswerIndex: 1,
                explanation: "due toは前置詞で、名詞（句）の前に使います。because/sinceは接続詞で後ろに節（主語+動詞）が来ます。",
                part: .part5
            ),
            Question(
                text: "We need _____ hire two new staff members this month.",
                options: ["to", "for", "at", "on"],
                correctAnswerIndex: 0,
                explanation: "need to 動詞原形で「〜する必要がある」という意味になります。needの後にはto不定詞が続きます。",
                part: .part5
            ),
            Question(
                text: "The sales figures were _____ impressive than expected.",
                options: ["most", "very", "more", "much more"],
                correctAnswerIndex: 2,
                explanation: "than（〜より）があるので比較級を使います。impressiveの比較級はmore impressiveです。",
                part: .part5
            ),
            Question(
                text: "Please send the documents _____ email by end of day.",
                options: ["with", "by", "via", "using"],
                correctAnswerIndex: 2,
                explanation: "「〜を通じて/〜経由で」という手段を表す場合はviaを使います。「メールで送る」はsend via emailです。",
                part: .part5
            ),
            Question(
                text: "The project has been _____ for three months.",
                options: ["delays", "delay", "delayed", "delaying"],
                correctAnswerIndex: 2,
                explanation: "has been + 過去分詞で現在完了形の受動態になります。「3ヶ月間遅延している」という意味です。",
                part: .part5
            ),
            Question(
                text: "All employees are required _____ attend the seminar.",
                options: ["to", "for", "at", "by"],
                correctAnswerIndex: 0,
                explanation: "be required to 動詞原形で「〜することを求められる/義務付けられる」という意味になります。",
                part: .part5
            ),
            Question(
                text: "The new software _____ make our work more efficient.",
                options: ["can", "should", "will", "must"],
                correctAnswerIndex: 2,
                explanation: "文脈から「新しいソフトウェアが業務を効率化するだろう」という推測・予測なので、willが最も適切です。",
                part: .part5
            ),
        ],
        difficultyLevel: .beginner
    )

    // MARK: Part 5 問題セット2（中級）
    static let part5Intermediate = QuestionSet(
        title: "Part 5 中級編 Vol.1",
        part: .part5,
        questions: [
            Question(
                text: "_____ the economic downturn, the company managed to increase its profits.",
                options: ["Despite", "Although", "However", "Because of"],
                correctAnswerIndex: 0,
                explanation: "despite（〜にもかかわらず）は前置詞で名詞句の前に置きます。althoughは接続詞で節が続きます。逆接の文脈に合います。",
                part: .part5
            ),
            Question(
                text: "The contract _____ be renewed before the end of the fiscal year.",
                options: ["must", "might", "could", "would"],
                correctAnswerIndex: 0,
                explanation: "「会計年度末までに更新されなければならない」という義務・必要性を表すにはmustが最適です。",
                part: .part5
            ),
            Question(
                text: "Mr. Yamamoto, _____ presentation impressed the board, has been promoted.",
                options: ["who", "whose", "which", "that"],
                correctAnswerIndex: 1,
                explanation: "関係代名詞whoseは所有格で「〜の」という意味。ここではMr. Yamamotoの発表（his presentation）を指しています。",
                part: .part5
            ),
            Question(
                text: "The new policy will _____ into effect next quarter.",
                options: ["come", "take", "go", "bring"],
                correctAnswerIndex: 0,
                explanation: "come into effectで「効力を持つ/発効する」という慣用表現です。ビジネス英語でよく使われます。",
                part: .part5
            ),
            Question(
                text: "Sales have increased _____ since the product launch.",
                options: ["significantly", "significance", "significant", "signify"],
                correctAnswerIndex: 0,
                explanation: "動詞（have increased）を修飾するのは副詞です。significantlyが副詞形で「大幅に」という意味になります。",
                part: .part5
            ),
            Question(
                text: "We are looking for someone _____ can communicate effectively in English.",
                options: ["which", "what", "who", "whose"],
                correctAnswerIndex: 2,
                explanation: "先行詞がsomeone（人）なので、関係代名詞はwhoを使います。whoは主格として使われています。",
                part: .part5
            ),
            Question(
                text: "The budget for next year has not yet been _____.",
                options: ["approve", "approving", "approved", "approvingly"],
                correctAnswerIndex: 2,
                explanation: "has not yet been + 過去分詞で現在完了受動態。「まだ承認されていない」という意味になります。",
                part: .part5
            ),
            Question(
                text: "_____ the deadline approaches, the team is working overtime.",
                options: ["As", "While", "Since", "Until"],
                correctAnswerIndex: 0,
                explanation: "as（〜するにつれて/〜するとき）は時間の経過とともに変化する状況を表します。「締め切りが近づくにつれて」が自然です。",
                part: .part5
            ),
        ],
        difficultyLevel: .intermediate
    )

    // MARK: Part 7 問題セット1（初級）
    static let part7Beginner = QuestionSet(
        title: "Part 7 初級編 Vol.1",
        part: .part7,
        questions: [
            Question(
                text: """
                    [メール本文]
                    From: HR Department
                    Subject: Annual Health Check Reminder

                    Dear Staff,
                    Please be reminded that the annual health check will be held on November 15th at the company clinic. All full-time employees are required to attend. Please bring your employee ID card.

                    Q: What is the purpose of this email?
                    """,
                options: [
                    "To announce a new health policy",
                    "To remind employees about the health check",
                    "To introduce the company clinic",
                    "To request employee ID cards"
                ],
                correctAnswerIndex: 1,
                explanation: "メールの件名がAnnual Health Check Reminderであり、本文もPlease be remindedで始まることから、健康診断のリマインドが目的です。",
                part: .part7
            ),
            Question(
                text: """
                    [お知らせ]
                    NOTICE: The office will be closed on December 25th and 26th for the Christmas holiday. Regular office hours will resume on December 27th. For urgent matters, please contact your manager directly.

                    Q: According to the notice, when will the office reopen?
                    """,
                options: [
                    "December 24th",
                    "December 25th",
                    "December 26th",
                    "December 27th"
                ],
                correctAnswerIndex: 3,
                explanation: "お知らせにRegular office hours will resume on December 27thとあるため、オフィスは12月27日に再開します。",
                part: .part7
            ),
            Question(
                text: """
                    [広告]
                    GRAND OPENING SALE
                    Tokyo Business Center
                    Opening Day: March 1st
                    
                    Enjoy 20% off all office supplies
                    Free parking for first 100 customers
                    Business hours: 9 AM - 8 PM

                    Q: What discount is offered at the grand opening?
                    """,
                options: [
                    "10% off all items",
                    "20% off office supplies",
                    "Free parking for all customers",
                    "30% off selected items"
                ],
                correctAnswerIndex: 1,
                explanation: "広告にEnjoy 20% off all office suppliesとあるため、オフィス用品が20%オフになります。無料駐車は最初の100名のみです。",
                part: .part7
            ),
        ],
        difficultyLevel: .beginner
    )

    // MARK: 全問題セット
    static let allQuestionSets: [QuestionSet] = [
        part5Beginner,
        part5Intermediate,
        part7Beginner,
    ]
}
