//
//  QuickEntryScreen.swift
//  Budgett
//
//  Blazing fast capture: amount first, everything else optional.
//

import SwiftUI
import SwiftData
import PhotosUI

struct QuickEntryScreen: View {
    var existing: Txn?
    var initialKind: TxnKind

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings

    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]
    @Query(sort: \Wallet.sortIndex) private var wallets: [Wallet]
    @Query private var budgets: [BudgetPlan]
    @Query private var allTxns: [Txn]

    @State private var entry = AmountEntry()
    @State private var kind: TxnKind
    @State private var title = ""
    @State private var note = ""
    @State private var tagsText = ""
    @State private var date = Date.now
    @State private var category: SpendCategory?
    @State private var wallet: Wallet?
    @State private var toWallet: Wallet?
    @State private var receipt: Data?
    @State private var isExcluded = false

    @State private var showCategoryPicker = false
    @State private var showDatePicker = false
    @State private var showExtras = false
    @State private var photoItem: PhotosPickerItem?
    @State private var makeRecurring = false
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var shake = false

    @FocusState private var titleFocused: Bool

    init(existing: Txn?, initialKind: TxnKind) {
        self.existing = existing
        self.initialKind = initialKind
        _kind = State(initialValue: existing?.kind ?? initialKind)
    }

    private var availableKinds: [TxnKind] {
        var kinds: [TxnKind] = [.expense]
        if settings.trackIncome { kinds.append(.income) }
        if wallets.count > 1 { kinds.append(.transfer) }
        return kinds
    }

    private var visibleCategories: [SpendCategory] {
        categories.filter { !$0.isArchived && $0.kind.matches(kind) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 4)
            amountBlock
            Spacer(minLength: 4)
            metaRow
                .padding(.horizontal, Metrics.hPadding)
                .padding(.bottom, 12)
            Keypad(style: settings.keypadStyle,
                   canSubmit: !entry.isEmpty || entry.hasPendingOperation,
                   isResolving: entry.hasPendingOperation) { key in
                handle(key)
            }
            .padding(.horizontal, Metrics.hPadding)
            .padding(.bottom, 8)
        }
        .background(AuroraBackground(accent: settings.accent))
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(selection: $category, kind: kind)
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(date: $date)
        }
        .sheet(isPresented: $showExtras) {
            extrasSheet
        }
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    receipt = data
                }
            }
        }
        .onAppear(perform: loadExisting)
        .interactiveDismissDisabled(!entry.isEmpty)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)

            Spacer(minLength: 8)

            if availableKinds.count > 1 {
                GlassSegmented(options: availableKinds, title: { $0.title }, selection: $kind)
                    .frame(maxWidth: 240)
                    .onChange(of: kind) { _, newValue in
                        if let category, !category.kind.matches(newValue) { self.category = nil }
                    }
            } else {
                Text("Yeni gider")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }

            Spacer(minLength: 8)

            Menu {
                Toggle("Tekrar eden yap", isOn: $makeRecurring)
                    .tint(Palette.controlTint)
                if makeRecurring {
                    Picker("Sıklık", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { Text($0.title).tag($0) }
                    }
                }
                Divider()
                Button("Daha fazla seçenek", systemImage: "slider.horizontal.3") { showExtras = true }
            } label: {
                Image(systemName: makeRecurring ? "arrow.trianglehead.2.clockwise.rotate.90.circle.fill" : "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(makeRecurring ? Color.primary : .secondary)
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, Metrics.hPadding)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    // MARK: Amount

    private var amountBlock: some View {
        VStack(spacing: 12) {
            if let expression = entry.expressionText {
                Text(expression)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if settings.currencyPresentation != .none {
                    Text(settings.currencyPresentation == .symbol
                         ? settings.currencySymbol
                         : settings.currencyCode)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text(entry.displayText)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: entry.displayText)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, 24)
            .offset(x: shake ? -8 : 0)

            TextField("Ne için?", text: $title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .focused($titleFocused)
                .submitLabel(.done)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .frame(maxWidth: 260)
                .glassCard(radius: 16)
        }
    }

    // MARK: Meta row

    private var metaRow: some View {
        VStack(spacing: 10) {
            if kind != .transfer {
                categoryStrip
            }

            HStack(spacing: 8) {
                pill(symbol: "calendar", text: dateLabel) { showDatePicker = true }

                if kind == .transfer {
                    Menu {
                        ForEach(wallets) { item in
                            Button(item.name) { wallet = item }
                        }
                    } label: {
                        pillLabel(symbol: "arrow.up.forward", text: wallet?.name ?? "Kaynak", tint: wallet?.color)
                    }
                    Menu {
                        ForEach(wallets.filter { $0.id != wallet?.id }) { item in
                            Button(item.name) { toWallet = item }
                        }
                    } label: {
                        pillLabel(symbol: "arrow.down.forward", text: toWallet?.name ?? "Hedef", tint: toWallet?.color)
                    }
                } else if !wallets.isEmpty {
                    Menu {
                        Button("Seçilmedi") { wallet = nil }
                        ForEach(wallets) { item in
                            Button {
                                wallet = item
                            } label: { Label(item.name, systemImage: item.symbol) }
                        }
                    } label: {
                        pillLabel(symbol: wallet?.symbol ?? "wallet.bifold",
                                  text: wallet?.name ?? "Cüzdan",
                                  tint: wallet?.color)
                    }
                }

                Spacer(minLength: 0)

                if receipt != nil {
                    Image(systemName: "paperclip")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Button {
                    showCategoryPicker = true
                    Haptics.tap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category?.symbol ?? "square.grid.2x2")
                            .font(.system(size: 12, weight: .bold))
                        Text(category?.name ?? "Kategori")
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background((category?.color ?? .secondary).opacity(0.18), in: Capsule())
                    .foregroundStyle(category?.color ?? .secondary)
                }
                .buttonStyle(.pressable)

                ForEach(suggestions) { item in
                    Button {
                        withAnimation(.snappy) { category = item }
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 11, weight: .bold))
                            Text(item.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .frame(height: 38)
    }

    /// Most used categories for this kind, minus the current selection.
    private var suggestions: [SpendCategory] {
        let counts = Dictionary(grouping: allTxns.filter { $0.kind == kind }) {
            $0.category?.id.uuidString ?? ""
        }.mapValues(\.count)
        return visibleCategories
            .filter { $0.id != category?.id }
            .sorted { (counts[$0.id.uuidString] ?? 0) > (counts[$1.id.uuidString] ?? 0) }
            .prefix(6)
            .map { $0 }
    }

    private var dateLabel: String {
        let cal = settings.calendar
        if cal.isDateInToday(date) { return "Bugün, \(date.timeTitle)" }
        if cal.isDateInYesterday(date) { return "Dün, \(date.timeTitle)" }
        return date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }

    private func pill(symbol: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { pillLabel(symbol: symbol, text: text, tint: nil) }
            .buttonStyle(.pressable)
    }

    private func pillLabel(symbol: String, text: String, tint: Color?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .foregroundStyle(tint ?? .secondary)
        .background((tint ?? Color.primary).opacity(0.08), in: Capsule())
    }

    // MARK: Extras

    private var extrasSheet: some View {
        NavigationStack {
            Form {
                Section("Not") {
                    TextField("Detay ekle", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Etiketler") {
                    TextField("kahve, iş, tatil", text: $tagsText)
                        .textInputAutocapitalization(.never)
                }
                Section("Fiş") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(receipt == nil ? "Fotoğraf ekle" : "Fotoğrafı değiştir",
                              systemImage: "camera.fill")
                    }
                    if let receipt, let image = UIImage(data: receipt) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Button("Fişi kaldır", role: .destructive) { self.receipt = nil }
                    }
                }
                Section {
                    Toggle("Analiz ve bütçe dışında tut", isOn: $isExcluded)
                        .tint(Palette.controlTint)
                    Toggle("Tekrar eden işlem", isOn: $makeRecurring)
                        .tint(Palette.controlTint)
                    if makeRecurring {
                        Picker("Sıklık", selection: $frequency) {
                            ForEach(RecurrenceFrequency.allCases) { Text($0.title).tag($0) }
                        }
                    }
                }
            }
            .navigationTitle("Detaylar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { showExtras = false }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: Actions

    private func handle(_ key: KeypadKey) {
        switch key {
        case .submit:
            if entry.hasPendingOperation {
                withAnimation(.snappy) { entry.resolve() }
            } else {
                save()
            }
        default:
            withAnimation(.snappy) { entry.input(key) }
        }
    }

    private func loadExisting() {
        guard let existing else {
            wallet = wallets.first
            return
        }
        entry.reset(to: existing.amount)
        title = existing.title
        note = existing.note
        tagsText = existing.tags.joined(separator: ", ")
        date = existing.date
        category = existing.category
        wallet = existing.wallet
        isExcluded = existing.isExcluded
        receipt = existing.receipt
        if let id = existing.toWalletID {
            toWallet = wallets.first { $0.id == id }
        }
    }

    private func save() {
        var working = entry
        working.resolve()
        let amount = working.value

        guard amount > 0 else {
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { shake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
            Haptics.warning()
            return
        }

        let tags = tagsText
            .split(whereSeparator: { $0 == "," || $0 == " " })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let txn: Txn
        if let existing {
            txn = existing
        } else {
            txn = Txn(amount: amount, kind: kind, date: date)
            context.insert(txn)
        }

        txn.amount = amount
        txn.kind = kind
        txn.date = date
        txn.title = title.trimmingCharacters(in: .whitespaces)
        txn.note = note
        txn.tags = tags
        txn.category = kind == .transfer ? nil : category
        txn.wallet = wallet
        txn.toWalletID = kind == .transfer ? toWallet?.id : nil
        txn.isExcluded = isExcluded
        txn.receipt = receipt
        txn.currencyCode = settings.currencyCode
        txn.updatedAt = .now

        if makeRecurring, existing == nil {
            let rule = Recurrence(title: txn.displayTitle,
                                  amount: amount,
                                  kind: kind,
                                  frequency: frequency,
                                  categoryID: category?.id.uuidString,
                                  walletID: wallet?.id.uuidString,
                                  startDate: frequency.next(after: date, cal: settings.calendar),
                                  colorHex: ThemeAccent.mono.hex,
                                  symbol: category?.symbol ?? "arrow.trianglehead.2.clockwise.rotate.90")
            context.insert(rule)
        }

        try? context.save()
        checkBudgets(for: txn)
        Haptics.success()
        dismiss()
    }

    private func checkBudgets(for txn: Txn) {
        guard settings.budgetAlerts, txn.kind == .expense else { return }
        let triggered = BudgetEngine.triggeredAlerts(for: txn, plans: budgets, txns: allTxns,
                                                     categories: categories, cal: settings.calendar)
        for status in triggered {
            let percent = Int(status.progress * 100)
            let remaining = Money.string(max(0, status.remaining), settings: settings)
            Task { await Notifier.budgetAlert(name: status.plan.name, percent: percent, remaining: remaining) }
        }
    }
}

// MARK: - Date picker sheet

struct DatePickerSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .tint(Palette.controlTint)
                    .padding(.horizontal, 8)

                HStack(spacing: 8) {
                    quick("Bugün", date: .now)
                    quick("Dün", date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
                    quick("Önceki gün", date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                Spacer(minLength: 0)
            }
            .navigationTitle("Tarih & saat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(520)])
    }

    private func quick(_ title: String, date value: Date) -> some View {
        Button {
            date = value
            Haptics.selection()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color.primary.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
