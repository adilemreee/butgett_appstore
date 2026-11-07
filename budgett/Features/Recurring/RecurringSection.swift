//
//  RecurringSection.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct RecurringSection: View {
    @Binding var showCreate: Bool

    @Environment(\.settings) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Recurrence.nextDate) private var rules: [Recurrence]

    @State private var editing: Recurrence?

    private var bills: [UpcomingBill] {
        RecurringEngine.upcoming(rules, within: 45, cal: settings.calendar)
    }

    private var monthlyOut: Decimal { RecurringEngine.monthlyLoad(rules, kind: .expense) }
    private var monthlyIn: Decimal { RecurringEngine.monthlyLoad(rules, kind: .income) }

    var body: some View {
        VStack(spacing: 12) {
            if rules.isEmpty {
                EmptyStateView(symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                               title: "Tekrar eden işlem yok",
                               message: "Kira, abonelik ve maaş gibi düzenli hareketleri tanımla; Budgett otomatik işlesin.",
                               actionTitle: "Tekrar ekle") { showCreate = true }
                    .glassCard()
                    .padding(.horizontal, Metrics.hPadding)
            } else {
                summary
                    .padding(.horizontal, Metrics.hPadding)

                if !bills.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Sıradaki ödemeler")
                        ForEach(bills.prefix(4)) { bill in
                            UpcomingRow(bill: bill)
                        }
                    }
                    .padding(16)
                    .glassCard()
                    .padding(.horizontal, Metrics.hPadding)
                }

                VStack(alignment: .leading, spacing: 4) {
                    SectionHeader(title: "Tümü")
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    ForEach(rules) { rule in
                        RecurrenceRow(rule: rule)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = rule }
                            .contextMenu {
                                Button(rule.isPaused ? "Devam ettir" : "Duraklat",
                                       systemImage: rule.isPaused ? "play.fill" : "pause.fill") {
                                    rule.isPaused.toggle()
                                }
                                Button("Düzenle", systemImage: "pencil") { editing = rule }
                                Button("Sil", systemImage: "trash", role: .destructive) {
                                    context.delete(rule)
                                }
                            }
                        if rule.id != rules.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .padding(14)
                .glassCard()
                .padding(.horizontal, Metrics.hPadding)
            }
        }
        .sheet(isPresented: $showCreate) { RecurrenceEditor(rule: nil) }
        .sheet(item: $editing) { rule in RecurrenceEditor(rule: rule) }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            StatTile(title: "Aylık gider yükü", amount: monthlyOut, symbol: "arrow.down.right")
            if monthlyIn > 0 {
                StatTile(title: "Aylık gelir", amount: monthlyIn, symbol: "arrow.up.right")
            } else {
                StatTile(title: "Aktif kayıt", amount: Decimal(rules.filter { !$0.isPaused }.count),
                         symbol: "repeat", isCurrency: false)
            }
        }
    }
}

struct RecurrenceRow: View {
    var rule: Recurrence
    @Environment(\.settings) private var settings

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(symbol: rule.symbol, color: rule.color, size: 40, filled: !rule.isPaused)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(rule.isPaused
                     ? "Duraklatıldı"
                     : "\(rule.frequency.title) · \(rule.nextDate.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                AmountLabel(amount: rule.kind == .expense ? -rule.amount : rule.amount,
                            sign: .always, size: 15,
                            tint: rule.kind == .income ? Palette.income : .primary)
                Text("~\(Money.string(rule.monthlyEquivalent, settings: settings))/ay")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 7)
        .opacity(rule.isPaused ? 0.55 : 1)
    }
}

// MARK: - Editor

struct RecurrenceEditor: View {
    var rule: Recurrence?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings

    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]
    @Query(sort: \Wallet.sortIndex) private var wallets: [Wallet]

    @State private var title = ""
    @State private var amountText = ""
    @State private var kind: TxnKind = .expense
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var nextDate = Date.now
    @State private var hasEnd = false
    @State private var endDate = Date.now.addingTimeInterval(365 * 86_400)
    @State private var categoryID: String?
    @State private var walletID: String?
    @State private var autoPost = true
    @State private var isPaused = false
    @State private var note = ""
    @State private var symbol = "arrow.trianglehead.2.clockwise.rotate.90"
    @State private var colorHex = "3B5BFF"

    private var tint: Color { Color(hex: colorHex) }

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
                        TextField("Başlık (ör. Spotify)", text: $title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    HStack {
                        Text(settings.currencySymbol).foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    Picker("Tür", selection: $kind) {
                        Text(TxnKind.expense.title).tag(TxnKind.expense)
                        Text(TxnKind.income.title).tag(TxnKind.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Zamanlama") {
                    Picker("Sıklık", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { Text($0.title).tag($0) }
                    }
                    DatePicker("Sıradaki", selection: $nextDate, displayedComponents: .date)
                        .tint(Palette.controlTint)
                    Toggle("Bitiş tarihi", isOn: $hasEnd.animation())
                        .tint(Palette.controlTint)
                    if hasEnd {
                        DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
                            .tint(Palette.controlTint)
                    }
                }

                Section("Bağlantılar") {
                    Picker("Kategori", selection: $categoryID) {
                        Text("Yok").tag(String?.none)
                        ForEach(categories.filter { $0.kind.matches(kind) }) { category in
                            Text(category.name).tag(String?.some(category.id.uuidString))
                        }
                    }
                    Picker("Cüzdan", selection: $walletID) {
                        Text("Yok").tag(String?.none)
                        ForEach(wallets) { wallet in
                            Text(wallet.name).tag(String?.some(wallet.id.uuidString))
                        }
                    }
                }

                Section {
                    Toggle("Otomatik işle", isOn: $autoPost)
                        .tint(Palette.controlTint)
                    Toggle("Duraklat", isOn: $isPaused)
                        .tint(Palette.controlTint)
                } footer: {
                    Text(autoPost
                         ? "Vakti geldiğinde işlem kendiliğinden akışa eklenir."
                         : "Sadece hatırlatma olarak listelenir, işlem oluşturulmaz.")
                }

                Section("Simge") {
                    SymbolGrid(symbols: Palette.categorySymbols, selection: $symbol, tint: .primary)
                }

                if let rule {
                    Section {
                        Button("Sil", role: .destructive) {
                            context.delete(rule)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(rule == nil ? "Yeni tekrar" : "Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || Money.decimal(from: amountText) <= 0)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let rule else { return }
        title = rule.title
        amountText = Money.number(rule.amount)
        kind = rule.kind
        frequency = rule.frequency
        nextDate = rule.nextDate
        categoryID = rule.categoryID
        walletID = rule.walletID
        autoPost = rule.autoPost
        isPaused = rule.isPaused
        note = rule.note
        symbol = rule.symbol
        colorHex = rule.colorHex
        if let end = rule.endDate {
            hasEnd = true
            endDate = end
        }
    }

    private func save() {
        let target: Recurrence
        if let rule {
            target = rule
        } else {
            target = Recurrence(title: title, amount: 0)
            context.insert(target)
        }
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.amount = Money.decimal(from: amountText)
        target.kind = kind
        target.frequency = frequency
        target.nextDate = nextDate
        target.endDate = hasEnd ? endDate : nil
        target.categoryID = categoryID
        target.walletID = walletID
        target.autoPost = autoPost
        target.isPaused = isPaused
        target.note = note
        target.symbol = symbol
        target.colorHex = colorHex
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
