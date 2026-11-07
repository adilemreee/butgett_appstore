//
//  GoalsSection.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct GoalsSection: View {
    @Binding var showCreate: Bool

    @Environment(\.settings) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.sortIndex) private var goals: [Goal]

    @State private var editing: Goal?
    @State private var contributing: Goal?

    private var active: [Goal] { goals.filter { !$0.isArchived } }

    var body: some View {
        VStack(spacing: 12) {
            if active.isEmpty {
                EmptyStateView(symbol: "target",
                               title: "Hedef belirle",
                               message: "Tatil, yeni telefon, acil durum fonu… biriktirdikçe halka dolsun.",
                               actionTitle: "Hedef oluştur") { showCreate = true }
                    .glassCard()
                    .padding(.horizontal, Metrics.hPadding)
            } else {
                totalCard
                    .padding(.horizontal, Metrics.hPadding)

                ForEach(active) { goal in
                    GoalCard(goal: goal) { contributing = goal }
                        .padding(.horizontal, Metrics.hPadding)
                        .contextMenu {
                            Button("Düzenle", systemImage: "pencil") { editing = goal }
                            Button("Para ekle", systemImage: "plus.circle") { contributing = goal }
                            Button("Sil", systemImage: "trash", role: .destructive) {
                                context.delete(goal)
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showCreate) { GoalEditor(goal: nil) }
        .sheet(item: $editing) { goal in GoalEditor(goal: goal) }
        .sheet(item: $contributing) { goal in ContributionSheet(goal: goal) }
    }

    private var totalCard: some View {
        let saved = active.reduce(Decimal(0)) { $0 + $1.saved }
        let target = active.reduce(Decimal(0)) { $0 + $1.target }
        let progress = target > 0 ? (saved / target).doubleValue : 0

        return HStack(spacing: 16) {
            ZStack {
                RingProgress(progress: progress, lineWidth: 9, tint: settings.accent.color)
                    .frame(width: 58, height: 58)
                Text("%\(Int(progress * 100))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Toplam birikim")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                AmountLabel(amount: saved, size: 22)
                Text("hedef: \(Money.string(target, settings: settings))")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard()
    }
}

struct GoalCard: View {
    var goal: Goal
    var onContribute: () -> Void

    @Environment(\.settings) private var settings

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RingProgress(progress: goal.progress, lineWidth: 7, tint: goal.color)
                        .frame(width: 48, height: 48)
                    Image(systemName: goal.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(goal.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.name)
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    HStack(spacing: 4) {
                        Text(Money.string(goal.saved, settings: settings))
                            .foregroundStyle(.primary)
                        Text("/ \(Money.string(goal.target, settings: settings))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                }

                Spacer(minLength: 0)

                Button {
                    onContribute()
                    Haptics.tap()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.glass)
                .tint(goal.color)
            }

            BudgetBar(progress: goal.progress, tint: goal.color, marker: nil, height: 8)

            HStack {
                if let days = goal.daysLeft, days >= 0 {
                    Label("\(days) gün", systemImage: "calendar")
                }
                Spacer()
                if let monthly = goal.suggestedMonthly, monthly > 0 {
                    Label("aylık \(Money.string(monthly, settings: settings))",
                          systemImage: "arrow.up.forward")
                } else if goal.progress >= 1 {
                    Label("Hedefe ulaşıldı", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Palette.income)
                }
            }
            .font(.system(size: 11.5, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassCard(radius: 24)
    }
}

// MARK: - Contribution

struct ContributionSheet: View {
    var goal: Goal

    @Environment(\.dismiss) private var dismiss
    @Environment(\.settings) private var settings
    @Environment(\.modelContext) private var context
    @State private var entry = AmountEntry()
    @State private var withdraw = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    ZStack {
                        RingProgress(progress: goal.progress, lineWidth: 9, tint: goal.color)
                            .frame(width: 74, height: 74)
                        Image(systemName: goal.symbol)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(goal.color)
                    }
                    Text(goal.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("\(Money.string(goal.saved, settings: settings)) / \(Money.string(goal.target, settings: settings))")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                Picker("İşlem", selection: $withdraw) {
                    Text("Ekle").tag(false)
                    Text("Çek").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Metrics.hPadding)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(settings.currencySymbol)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(entry.displayText)
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)

                Keypad(style: .simple, canSubmit: !entry.isEmpty) { key in
                    if case .submit = key { commit() } else { withAnimation(.snappy) { entry.input(key) } }
                }
                .padding(.horizontal, Metrics.hPadding)
                .padding(.bottom, 10)
            }
            .background(AuroraBackground(accent: settings.accent))
            .navigationTitle(withdraw ? "Para çek" : "Para ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
            }
        }
    }

    private func commit() {
        let amount = entry.value
        guard amount > 0 else { return }
        goal.saved = max(0, withdraw ? goal.saved - amount : goal.saved + amount)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

// MARK: - Editor

struct GoalEditor: View {
    var goal: Goal?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings
    @Query private var goals: [Goal]

    @State private var name = ""
    @State private var targetText = ""
    @State private var savedText = ""
    @State private var hasDeadline = false
    @State private var deadline = Date.now.addingTimeInterval(90 * 86_400)
    @State private var colorHex = "16C47F"
    @State private var symbol = "target"

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
                        TextField("Hedef adı", text: $name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    HStack {
                        Text("Hedef tutar")
                        Spacer()
                        Text(settings.currencySymbol).foregroundStyle(.secondary)
                        TextField("0", text: $targetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 130)
                    }
                    HStack {
                        Text("Mevcut birikim")
                        Spacer()
                        Text(settings.currencySymbol).foregroundStyle(.secondary)
                        TextField("0", text: $savedText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 130)
                    }
                }

                Section {
                    Toggle("Son tarih", isOn: $hasDeadline.animation())
                        .tint(Palette.controlTint)
                    if hasDeadline {
                        DatePicker("Tarih", selection: $deadline, displayedComponents: .date)
                            .tint(Palette.controlTint)
                    }
                }

                Section("Simge") {
                    SymbolGrid(symbols: Palette.goalSymbols, selection: $symbol, tint: .primary)
                }

                if let goal {
                    Section {
                        Button("Hedefi sil", role: .destructive) {
                            context.delete(goal)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(goal == nil ? "Yeni hedef" : "Hedefi düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Money.decimal(from: targetText) <= 0)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let goal else { return }
        name = goal.name
        targetText = Money.number(goal.target, showCents: false)
        savedText = Money.number(goal.saved, showCents: false)
        colorHex = goal.colorHex
        symbol = goal.symbol
        if let deadline = goal.deadline {
            hasDeadline = true
            self.deadline = deadline
        }
    }

    private func save() {
        let target: Goal
        if let goal {
            target = goal
        } else {
            target = Goal(name: name, target: 0, sortIndex: (goals.map(\.sortIndex).max() ?? 0) + 1)
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.target = Money.decimal(from: targetText)
        target.saved = Money.decimal(from: savedText)
        target.deadline = hasDeadline ? deadline : nil
        target.colorHex = colorHex
        target.symbol = symbol
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
