// SheetDetailView.swift
// TOEICApp - 解答シート詳細画面

import SwiftUI

struct SheetDetailView: View {

    @EnvironmentObject var dataManager: DataManager
    @State var sheet: AnswerSheet
    @State private var activeViewModel: AnswerSheetViewModel?  // VM を事前生成して保持
    @State private var showScoringResult = false
    @State private var showWrongAnswers = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ステータスカード
                statusCard

                // 進捗情報
                progressCard

                // アクションボタン
                actionButtons

                // タイマー情報
                if sheet.elapsedSeconds > 0 {
                    timerCard
                }
            }
            .padding()
        }
        .navigationTitle(sheet.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if sheet.status != .scored {  // 採点済み以外は削除可能
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("解答シートを削除しますか？", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                dataManager.deleteSheet(sheet)
                dismiss()
            }
        } message: {
            Text("この解答シートを削除します。この操作は元に戻せません。")
        }
        .fullScreenCover(item: $activeViewModel, onDismiss: {
            // カバーを閉じたらシートを再読み込み
            reloadSheet()
        }) { vm in
            AnswerInputView(viewModel: vm)
        }
        .sheet(isPresented: $showScoringResult) {
            reloadSheet()
        } content: {
            ScoringResultView(sheet: sheet)
        }
        .sheet(isPresented: $showWrongAnswers) {
            WrongAnswersView(sheet: sheet)
        }
    }

    // MARK: - ステータスカード
    private var statusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("ステータス")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(sheet.status.label)
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Spacer()

            statusBadge
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var statusBadge: some View {
        let color = statusColor
        return Circle()
            .fill(color.opacity(0.15))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: statusIcon)
                    .foregroundColor(color)
                    .font(.title3)
            )
    }

    private var statusColor: Color {
        switch sheet.status {
        case .answering:    return .blue
        case .answered:     return .orange
        case .scoring:      return .purple
        case .scored:       return .green
        case .correctInput: return .purple
        case .correctReady: return .orange
        }
    }

    private var statusIcon: String {
        switch sheet.status {
        case .answering:    return "pencil"
        case .answered:     return "checkmark.circle"
        case .scoring:      return "doc.text.magnifyingglass"
        case .scored:       return "star.fill"
        case .correctInput: return "doc.text.magnifyingglass"
        case .correctReady: return "checkmark.circle"
        }
    }

    // MARK: - 進捗カード
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("回答状況")
                    .font(.headline)
                Spacer()
                Text("\(sheet.answeredCount) / \(TOEICTemplate.totalQuestions)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(sheet.answeredCount), total: Double(TOEICTemplate.totalQuestions))
                .tint(.blue)

            if [.scoring, .scored, .correctInput, .correctReady].contains(sheet.status) {
                HStack {
                    Text("正解入力")
                        .font(.headline)
                    Spacer()
                    Text("\(sheet.correctAnswersEnteredCount) / \(TOEICTemplate.totalQuestions)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(sheet.correctAnswersEnteredCount), total: Double(TOEICTemplate.totalQuestions))
                    .tint(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - アクションボタン
    private var actionButtons: some View {
        VStack(spacing: 12) {
            switch sheet.status {
            case .answering:
                primaryButton(title: "回答を続ける", icon: "pencil") {
                    activeViewModel = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                }

            case .answered:
                primaryButton(title: "正解を入力する", icon: "checkmark.circle") {
                    // 正解入力モードに切り替えて開く
                    sheet.status = .scoring
                    dataManager.updateSheet(sheet)
                    activeViewModel = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                }
                secondaryButton(title: "回答を修正する", icon: "pencil") {
                    sheet.status = .answering
                    dataManager.updateSheet(sheet)
                    activeViewModel = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                }

            case .scoring:
                primaryButton(title: "正解入力を続ける", icon: "doc.text.magnifyingglass") {
                    activeViewModel = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                }
                if sheet.isFullyCorrectAnswered {
                    primaryButton(title: "採点する", icon: "star.fill") {
                        sheet.status = .scored
                        dataManager.updateSheet(sheet)
                        reloadSheet()
                        showScoringResult = true
                    }
                }

            case .scored:
                primaryButton(title: "採点結果を見る", icon: "chart.bar") {
                    showScoringResult = true
                }
                if !sheet.wrongAnswers.isEmpty {
                    secondaryButton(title: "間違えた問題を見る (\(sheet.wrongAnswers.count)問)", icon: "xmark.circle") {
                        showWrongAnswers = true
                    }
                }

            case .correctInput:
                // 正解先行パターン: 正解入力中
                primaryButton(title: "正解入力を続ける", icon: "doc.text.magnifyingglass") {
                    activeViewModel = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                }

            case .correctReady:
                // 正解先行パターン: 正解入力完了、回答待ち
                primaryButton(title: "回答を入力する", icon: "pencil") {
                    sheet.status = .answering
                    dataManager.updateSheet(sheet)
                    activeViewModel = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                }
                secondaryButton(title: "正解を修正する", icon: "doc.text.magnifyingglass") {
                    sheet.status = .correctInput
                    dataManager.updateSheet(sheet)
                    activeViewModel = AnswerSheetViewModel(sheet: sheet, dataManager: dataManager)
                }
            }
        }
    }

    private func primaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
    }

    private func secondaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(14)
        }
    }

    // MARK: - タイマーカード
    private var timerCard: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            Text("経過時間")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(sheet.formattedTime)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - ヘルパー
    private func reloadSheet() {
        if let updated = dataManager.sheets.first(where: { $0.id == sheet.id }) {
            sheet = updated
        }
    }
}

#Preview {
    NavigationStack {
        SheetDetailView(sheet: AnswerSheet(title: "テスト解答シート"))
            .environmentObject(DataManager.shared)
    }
}
