//
//  InsightsScreen.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct InsightsScreen: View {
    @Environment(\.settings) private var settings

    @Query(sort: \Txn.date, order: .reverse) private var txns: [Txn]

    @State private var cursor = PeriodCursor(period: .month)
    @State private var breakdownKind: TxnKind = .expense
    @State private var focused: CategorySlice?

    private var cal: Calendar { settings.calendar }
    private var interval: DateInterval { cursor.interval(cal) }

    private var current: [Txn] { txns.filter { interval.contains($0.date) && !$0.isUpcoming } }
    private var previous: [Txn] {
        let range = cursor.previousInterval(cal)
        return txns.filter { range.contains($0.date) }
    }

    private var stats: PeriodStats { InsightsEngine.stats(current, interval: interval) }
    private var previousStats: PeriodStats {
        InsightsEngine.stats(previous, interval: cursor.previousInterval(cal))
    }
    private var buckets: [TimeBucket] { InsightsEngine.buckets(current, cursor: cursor, cal: cal) }
    private var slices: [CategorySlice] { InsightsEngine.slices(current, kind: breakdownKind) }

    private var averagePerBucket: Decimal {
        let active = buckets.filter { $0.expense > 0 }
        guard !active.isEmpty else { return 0 }
        return (active.reduce(Decimal(0)) { $0 + $1.expense } / Decimal(active.count)).rounded(0)
    }

    /// Change against the same window one period back, nil when there is nothing
    /// meaningful to compare.
    private var trend: Double? {
        guard previousStats.expense > 0, stats.expense > 0 else { return nil }
        let delta = ((stats.expense - previousStats.expense) / previousStats.expense).doubleValue
        return abs(delta) < 0.02 ? nil : delta
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    header

                    SpendChartCard(buckets: buckets, period: cursor.period, average: averagePerBucket)

                    if settings.trackIncome {
                        GlassSegmented(options: [TxnKind.expense, .income],
                                       title: { $0.title },
                                       selection: $breakdownKind)
                    }

                    CategoryBreakdownCard(
                        slices: slices,
                        total: breakdownKind == .expense ? stats.expense : stats.income,
                        kind: breakdownKind,
                        onSelect: { focused = $0 }
                    )

                    Color.clear.frame(height: Metrics.tabBarClearance)
                }
                .padding(.horizontal, Metrics.hPadding)
                .padding(.top, 4)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Analiz")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $focused) { slice in
                CategoryDetailSheet(slice: slice, interval: interval, txns: current)
            }
            .onAppear { cursor.period = settings.defaultPeriod }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            PeriodNavigator(cursor: $cursor)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("HARCAMA")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.tertiary)
                    AmountLabel(amount: stats.expense, size: 32)
                    if let trend {
                        Label("önceki döneme göre %\(Int(abs(trend) * 100)) \(trend > 0 ? "fazla" : "az")",
                              systemImage: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("GÜNLÜK")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.tertiary)
                    AmountLabel(amount: stats.perDay, size: 20, tint: .secondary)
                }
            }

            if settings.trackIncome {
                HStack(spacing: 10) {
                    StatTile(title: "Gelir", amount: stats.income, symbol: "arrow.up.right")
                    StatTile(title: "Net", amount: stats.net, symbol: "equal")
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Category drill down

struct CategoryDetailSheet: View {
    var slice: CategorySlice
    var interval: DateInterval
    var txns: [Txn]

    @Environment(\.dismiss) private var dismiss

    private var items: [Txn] {
        txns
            .filter { ($0.category?.id.uuidString ?? "uncategorised") == slice.id }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 10) {
                        CategoryBadge(symbol: slice.symbol, size: 52)
                        AmountLabel(amount: slice.total, size: 28)
                        Text("\(slice.count) işlem · toplamın %\(Int(slice.share * 100))'i")
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    ForEach(items) { txn in
                        TxnRow(txn: txn, showDate: true)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    SectionHeader(title: "İşlemler")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AuroraBackground())
            .navigationTitle(slice.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
