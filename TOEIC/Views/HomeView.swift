// HomeView.swift
// TOEICApp - 解答シート一覧 (SwiftData対応)

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 実施中（採点済みでない）シートを取得
    @Query(filter: #Predicate<AnswerSheet> { $0.statusRaw != 3 }, sort: \AnswerSheet.createdAt, order: .reverse)
    private var activeSheets: [AnswerSheet]
    
    // 採点済みシートを取得
    @Query(filter: #Predicate<AnswerSheet> { $0.statusRaw == 3 }, sort: \AnswerSheet.createdAt, order: .reverse)
    private var scoredSheets: [AnswerSheet]
    
    @State private var showingCreateSheet = false
    @State private var showingStatistics = false
    @State private var activeViewModel: AnswerSheetViewModel?
    
    // エラーハンドリング用
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                if activeSheets.isEmpty && scoredSheets.isEmpty {
                    emptyView
                } else {
                    sheetList
                }
                
                floatingActionButton
            }
            .navigationTitle("TOEIC 解答シート")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingStatistics = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                }
            }
            .sheet(isPresented: $showingStatistics) {
                NavigationStack {
                    StatisticsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("閉じる") { showingStatistics = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSheetView()
            }
            .fullScreenCover(item: $activeViewModel) { vm in
                AnswerInputView(viewModel: vm)
            }
            .alert("エラー", isPresented: $showingErrorAlert, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private var sheetList: some View {
        List {
            if !activeSheets.isEmpty {
                Section(header: Text("実施中")) {
                    ForEach(activeSheets) { sheet in
                        SheetRowView(sheet: sheet)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeViewModel = AnswerSheetViewModel(sheet: sheet)
                            }
                    }
                    .onDelete(perform: deleteActiveSheets)
                }
            }
            
            if !scoredSheets.isEmpty {
                let recentScored = Array(scoredSheets.prefix(5))
                Section(header: scoredHeader(count: scoredSheets.count)) {
                    ForEach(recentScored) { sheet in
                        NavigationLink(destination: SheetDetailView(sheet: sheet)) {
                            SheetRowView(sheet: sheet)
                        }
                    }
                }
            }
        }
    }
    
    private func scoredHeader(count: Int) -> some View {
        HStack {
            Text("最近の採点済み")
            if count > 5 {
                Spacer()
                Text("ほか \(count - 5) 件は履歴へ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("解答シートがありません")
                .font(.headline)
            Text("右下のボタンから新しいシートを作成しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }

    private func deleteActiveSheets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activeSheets[index])
        }
        do {
            try modelContext.save()
        } catch {
            errorMessage = "データの削除に失敗しました: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - 行表示用View
struct SheetRowView: View {
    let sheet: AnswerSheet
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sheet.title)
                    .font(.headline)
                Text(sheet.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            statusBadge
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        Text(sheet.status.label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch sheet.status {
        case .answering: return .blue
        case .answered: return .green
        case .scoring: return .orange
        case .scored: return .secondary
        case .correctInput: return .purple
        case .correctReady: return .orange
        }
    }
}
