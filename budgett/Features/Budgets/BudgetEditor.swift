//
//  BudgetEditor.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct BudgetEditor: View {
    var plan: BudgetPlan?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings

    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]
    @Query private var plans: [BudgetPlan]

    @State private var name = ""
    @State private var amountText = ""
    @State private var period: BudgetPeriod = .month
    @State private var selected: Set<String> = []
    @State private var colorHex = "3B5BFF"
    @State private var symbol = "chart.pie.fill"
    @State private var rollover = false
    @State private var notifyEnabled = true
    @State private var notifyPercent = 80.0

    private var tint: Color { Color(hex: colorHex) }
    private var expenseCategories: [SpendCategory] {
        categories.filter { !$0.isArchived && $0.kind != .income }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(tint)
                            .frame(width: 34, height: 34)
                            .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        TextField("Bütçe adı", text: $name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    HStack {
                        Text(settings.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    Picker("Dönem", selection: $period) {
                        ForEach(BudgetPeriod.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section {
                    Toggle("Tüm giderleri kapsa", isOn: Binding(
                        get: { selected.isEmpty },
                        set: { all in
                            if all { selected.removeAll() }
                            else if let first = expenseCategories.first { selected = [first.id.uuidString] }
                        }))
                        .tint(Palette.controlTint)
                    if !selected.isEmpty {
                        ChipFlow(items: expenseCategories.map {
                            ChipItem(id: $0.id.uuidString, title: $0.name,
                                     colorHex: $0.colorHex, symbol: $0.symbol)
                        }, selection: $selected)
                    }
                } header: {
                    Text("Kapsam")
                } footer: {
                    Text(selected.isEmpty
                         ? "Genel bütçe: tüm harcamalar sayılır ve ana göstergede görünür."
                         : "Sadece seçili kategorilerdeki harcamalar bu bütçeden düşer.")
                }

                Section("Simge") {
                    SymbolGrid(symbols: Palette.categorySymbols, selection: $symbol, tint: .primary)
                }

                Section {
                    Toggle("Kalanı sonraki döneme aktar", isOn: $rollover)
                        .tint(Palette.controlTint)
                    Toggle("Limit uyarısı", isOn: $notifyEnabled)
                        .tint(Palette.controlTint)
                    if notifyEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("%\(Int(notifyPercent)) harcandığında uyar")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                            Slider(value: $notifyPercent, in: 50...100, step: 5)
                                .tint(tint)
                        }
                    }
                } header: {
                    Text("Davranış")
                }

                if let plan {
                    Section {
                        Button("Bütçeyi sil", role: .destructive) {
                            context.delete(plan)
                            Haptics.warning()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(plan == nil ? "Yeni bütçe" : "Bütçeyi düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Money.decimal(from: amountText) <= 0)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let plan else { return }
        name = plan.name
        amountText = Money.number(plan.amount, showCents: false)
        period = plan.period
        selected = Set(plan.categoryIDs)
        colorHex = plan.colorHex
        symbol = plan.symbol
        rollover = plan.rollover
        notifyEnabled = plan.notifyAtPercent > 0
        notifyPercent = Double(plan.notifyAtPercent == 0 ? 80 : plan.notifyAtPercent)
    }

    private func save() {
        let target: BudgetPlan
        if let plan {
            target = plan
        } else {
            target = BudgetPlan(name: name, amount: 0,
                                sortIndex: (plans.map(\.sortIndex).max() ?? 0) + 1)
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.amount = Money.decimal(from: amountText)
        target.period = period
        target.categoryIDs = Array(selected)
        target.colorHex = colorHex
        target.symbol = symbol
        target.rollover = rollover
        target.notifyAtPercent = notifyEnabled ? Int(notifyPercent) : 0
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

// MARK: - Detail

struct BudgetDetailSheet: View {
    var planID: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.settings) private var settings
    @Query private var plans: [BudgetPlan]
    @Query(sort: \Txn.date, order: .reverse) private var txns: [Txn]
    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]
    @State private var showEditor = false

    private var plan: BudgetPlan? { plans.first { $0.id == planID } }

    var body: some View {
        NavigationStack {
            Group {
                if let plan {
                    let status = BudgetEngine.status(for: plan, txns: txns,
                                                     categories: categories, cal: settings.calendar)
                    let items = txns.filter {
                        BudgetEngine.matches($0, plan: plan) && status.interval.contains($0.date)
                    }
                    content(status: status, items: items)
                } else {
                    EmptyStateView(symbol: "questionmark.folder",
                                   title: "Bütçe bulunamadı",
                                   message: "Bu bütçe silinmiş olabilir.")
                }
            }
            .background(AuroraBackground(accent: settings.accent))
            .navigationTitle(plan?.name ?? "Bütçe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Kapat") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Düzenle") { showEditor = true }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showEditor) {
                if let plan { BudgetEditor(plan: plan) }
            }
        }
    }

    private func content(status: BudgetStatus, items: [Txn]) -> some View {
        List {
            Section {
                OverallGaugeCard(status: status)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if !status.categories.isEmpty {
                Section {
                    FlowLayout(spacing: 8) {
                        ForEach(status.categories) { category in
                            HStack(spacing: 5) {
                                Image(systemName: category.symbol)
                                    .font(.system(size: 10, weight: .bold))
                                Text(category.name)
                                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(category.color.opacity(0.16), in: Capsule())
                            .foregroundStyle(category.color)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    SectionHeader(title: "Kapsam")
                }
            }

            Section {
                if items.isEmpty {
                    Text("Bu dönemde harcama yok.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(items) { txn in
                        TxnRow(txn: txn, showDate: true)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                SectionHeader(title: "Harcamalar",
                              trailing: Money.string(status.spent, settings: settings))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
