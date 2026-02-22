// SheetDetailView.swift
// TOEICApp - シート詳細画面 (SwiftData対応)

import SwiftUI
import SwiftData
import Charts

struct SheetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable let sheet: AnswerSheet
    
    @State private var activeViewModel: AnswerSheetViewModel?
    @State private var showingDeleteAlert = false
    @State private var showingWrongAnswers = false

    var body: some View {
        List {
            Section(header: Text("ステータス")) {
                statusRow
            }
            
            if sheet.status == .scored {
                Section(header: Text("パート別正解率")) {
                    performanceChart
                        .frame(height: 160)
                        .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("アクション")) {
                actionButtons
            }
            
            Section(header: Text("シート情報")) {
                HStack {
                    Text("作成日")
                    Spacer()
                    Text(sheet.createdAt, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("このシートを削除")
                    }
                }
            }
        }
        .navigationTitle(sheet.title)
        .alert("シートの削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                deleteSheet()
            }
        } message: {
            Text("この解答シートを削除してもよろしいですか？")
        }
        .fullScreenCover(item: $activeViewModel) { vm in
            AnswerInputView(viewModel: vm)
        }
        .sheet(isPresented: $showingWrongAnswers) {
            WrongAnswersView(sheet: sheet)
        }
    }

    private var statusRow: some View {
        HStack {
            Text(sheet.status.label)
                .font(.headline)
            Spacer()
            if sheet.status == .scored {
                Text("\(sheet.totalCorrect) / 200")
                    .font(.title2.bold())
                    .foregroundColor(.blue)
            } else {
                Text("\(sheet.answeredCount) / 200 入力済")
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch sheet.status {
        case .answering:
            Button {
                activeViewModel = AnswerSheetViewModel(sheet: sheet)
            } label: {
                Label("解答を続ける", systemImage: "pencil")
            }
            
        case .answered:
            Button {
                activeViewModel = AnswerSheetViewModel(sheet: sheet)
            } label: {
                Label("正解を入力する", systemImage: "checkmark.circle")
            }
            
        case .scoring:
            Button {
                activeViewModel = AnswerSheetViewModel(sheet: sheet)
            } label: {
                Label("採点を再開する", systemImage: "divider.circle")
            }
            
        case .scored:
            Button {
                showingWrongAnswers = true
            } label: {
                Label("間違えた問題を確認", systemImage: "xmark.circle")
            }
            
            Button {
                sheet.status = .answering
                activeViewModel = AnswerSheetViewModel(sheet: sheet)
            } label: {
                Label("もう一度解き直す", systemImage: "arrow.counterclockwise")
            }
            
        case .correctInput:
            Button {
                activeViewModel = AnswerSheetViewModel(sheet: sheet)
            } label: {
                Label("正解入力を続ける", systemImage: "checkmark.seal")
            }
            
        case .correctReady:
            Button {
                activeViewModel = AnswerSheetViewModel(sheet: sheet)
            } label: {
                Label("本番解答を開始", systemImage: "play.circle")
            }
        }
    }

    private func deleteSheet() {
        modelContext.delete(sheet)
        do { try modelContext.save() } catch { print("Failed to save: \(error)") }
        dismiss()
    }

    private var performanceChart: some View {
        Chart {
            ForEach(sheet.partScores) { partScore in
                BarMark(
                    x: .value("パート", "P\(partScore.part.rawValue)"),
                    y: .value("正解率", partScore.percentage)
                )
                .foregroundStyle(barColor(for: partScore.percentage).gradient)
                .cornerRadius(4)
            }
            
            RuleMark(y: .value("平均", sheet.scorePercentage))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .foregroundStyle(.secondary)
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
    }

    private func barColor(for percentage: Double) -> Color {
        switch percentage {
        case 80...100: return .green
        case 60..<80:  return .orange
        default:       return .red
        }
    }
}
