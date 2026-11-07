//
//  FlowScreen.swift
//  Budgett
//
//  The main ledger: hero summary, upcoming bills and a day-grouped list.
//

import SwiftUI
import SwiftData

struct DayGroup: Identifiable {
    var id: Date { day }
    var day: Date
    var items: [Txn]

    var total: Decimal { items.reduce(Decimal(0)) { $0 + $1.signedAmount } }
}

struct FlowScreen: View {
    @Environment(\.settings) private var settings
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context

    @Query(sort: \Txn.date, order: .reverse) private var txns: [Txn]
    @Query private var recurrences: [Recurrence]
    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]
    @Query(sort: \Wallet.sortIndex) private var wallets: [Wallet]

    @State private var cursor = PeriodCursor(period: .month)
    @State private var search = ""
    @State private var filter = TxnFilter()
    @State private var showFilters = false
    @State private var detail: Txn?

    private var cal: Calendar { settings.calendar }
    private var interval: DateInterval { cursor.interval(cal) }

    private var visible: [Txn] {
        txns.filter {
            interval.contains($0.date) && filter.matches($0) && filter.matches(search: search, $0)
        }
    }

    private var past: [Txn] { visible.filter { !$0.isUpcoming } }
    private var future: [Txn] { visible.filter { $0.isUpcoming }.sorted { $0.date < $1.date } }

    private var stats: PeriodStats { InsightsEngine.stats(past, interval: interval) }

    private var groups: [DayGroup] {
        Dictionary(grouping: past) { cal.startOfDay(for: $0.date) }
            .map { DayGroup(day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    private var upcomingBills: [UpcomingBill] {
        guard settings.carryUpcoming, search.isEmpty, !filter.isActive else { return [] }
        return RecurringEngine.upcoming(recurrences, within: 14, cal: cal)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    FlowHeroCard(cursor: $cursor, stats: stats)
                        .padding(.bottom, 6)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if !future.isEmpty || !upcomingBills.isEmpty {
                    Section {
                        ForEach(future) { txn in
                            row(txn, showDate: true)
                        }
                        ForEach(upcomingBills) { bill in
                            UpcomingRow(bill: bill)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    } header: {
                        SectionHeader(title: "Yaklaşan",
                                      trailing: Money.string(upcomingTotal, settings: settings, sign: .negativeOnly))
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { txn in
                            row(txn)
                        }
                    } header: {
                        SectionHeader(title: group.day.dayTitle(cal),
                                      trailing: Money.string(group.total, settings: settings, sign: .always),
                                      trailingColor: group.total >= 0 ? Palette.income : .secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if groups.isEmpty && future.isEmpty {
                    Section {
                        EmptyStateView(
                            symbol: search.isEmpty ? "tray" : "magnifyingglass",
                            title: search.isEmpty ? "Bu dönemde kayıt yok" : "Sonuç bulunamadı",
                            message: search.isEmpty
                                ? "Alttaki + tuşuna basarak ilk işlemini ekle."
                                : "Farklı bir arama ya da filtre dene.",
                            actionTitle: search.isEmpty ? "İşlem ekle" : nil,
                            action: search.isEmpty ? { router.newTransaction() } : nil
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Color.clear
                    .frame(height: Metrics.tabBarClearance)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .listSectionSpacing(14)
            .scrollContentBackground(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .navigationTitle("Akış")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "İşlem, kategori, tutar ara")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: filter.isActive
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                    .tint(filter.isActive ? settings.accent.color : .primary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Gider ekle", systemImage: "minus.circle") { router.newTransaction(kind: .expense) }
                        if settings.trackIncome {
                            Button("Gelir ekle", systemImage: "plus.circle") { router.newTransaction(kind: .income) }
                        }
                        if wallets.count > 1 {
                            Button("Transfer", systemImage: "arrow.left.arrow.right") { router.newTransaction(kind: .transfer) }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filter: $filter, categories: categories, wallets: wallets, tags: allTags)
            }
            .sheet(item: $detail) { txn in
                TxnDetailSheet(txn: txn)
            }
            .onAppear { cursor.period = settings.defaultPeriod }
        }
    }

    private var upcomingTotal: Decimal {
        let a = future.reduce(Decimal(0)) { $0 + $1.signedAmount }
        let b = upcomingBills.reduce(Decimal(0)) { $0 + ($1.rule.kind == .expense ? -$1.rule.amount : $1.rule.amount) }
        return a + b
    }

    private var allTags: [String] {
        Array(Set(txns.flatMap(\.tags))).sorted()
    }

    @ViewBuilder
    private func row(_ txn: Txn, showDate: Bool = false) -> some View {
        Button {
            detail = txn
            Haptics.tap(.soft)
        } label: {
            TxnRow(txn: txn, showDate: showDate)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { context.delete(txn) }
                Haptics.warning()
            } label: { Label("Sil", systemImage: "trash") }

            Button {
                router.edit(txn)
            } label: { Label("Düzenle", systemImage: "pencil") }
                .tint(Palette.actionFill)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                duplicate(txn)
            } label: { Label("Kopyala", systemImage: "doc.on.doc") }
                .tint(Palette.actionFill)

            Button {
                txn.isExcluded.toggle()
                txn.updatedAt = .now
            } label: {
                Label(txn.isExcluded ? "Dahil et" : "Hariç tut",
                      systemImage: txn.isExcluded ? "eye" : "eye.slash")
            }
            .tint(.gray)
        }
        .contextMenu {
            Button("Düzenle", systemImage: "pencil") { router.edit(txn) }
            Button("Kopyala", systemImage: "doc.on.doc") { duplicate(txn) }
            Button(txn.isExcluded ? "Analize dahil et" : "Analizden çıkar",
                   systemImage: txn.isExcluded ? "eye" : "eye.slash") {
                txn.isExcluded.toggle()
            }
            Divider()
            Button("Sil", systemImage: "trash", role: .destructive) {
                withAnimation { context.delete(txn) }
            }
        }
    }

    private func duplicate(_ txn: Txn) {
        let copy = Txn(amount: txn.amount, kind: txn.kind, date: .now,
                       title: txn.title, note: txn.note,
                       category: txn.category, wallet: txn.wallet,
                       tags: txn.tags, currencyCode: txn.currencyCode)
        context.insert(copy)
        Haptics.success()
    }
}

// MARK: - Hero

struct FlowHeroCard: View {
    @Binding var cursor: PeriodCursor
    var stats: PeriodStats

    @Environment(\.settings) private var settings

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(settings.trackIncome ? "Net toplam" : "Toplam harcama")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                AmountLabel(amount: settings.trackIncome ? stats.net : -stats.expense,
                            sign: .always, size: 34)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PeriodNavigator(cursor: $cursor)

            HStack(spacing: 10) {
                if settings.trackIncome {
                    StatTile(title: "Gelir", amount: stats.income, symbol: "arrow.up.right")
                    StatTile(title: "Gider", amount: stats.expense, symbol: "arrow.down.right")
                } else {
                    StatTile(title: "Günlük ortalama", amount: stats.perDay, symbol: "calendar")
                    StatTile(title: "İşlem", amount: Decimal(stats.count),
                             symbol: "number", isCurrency: false)
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}
