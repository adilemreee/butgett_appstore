//
//  WatchHomeView.swift
//  BudgettWatch
//
//  A single calm screen: today, the week bars, the budget gauge and the latest
//  transactions. The snapshot refreshes every time the app comes to the front.
//

import SwiftUI
import Foundation

struct WatchHomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = WatchSyncStore.shared
    @State private var showEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = store.snapshot {
                    SummaryList(snapshot: snapshot)
                } else {
                    EmptyStateView()
                }
            }
            .navigationTitle {
                Text("Budgett")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showEntry) {
            QuickEntryScreen()
        }
        .task { store.activate() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.loadFromDisk() }
        }
    }
}

// MARK: - Content

private struct SummaryList: View {
    let snapshot: BudgettSnapshot

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HeroCard(snapshot: snapshot)

                if !snapshot.privacyMode {
                    WatchBars(days: snapshot.days, tint: .primary)
                        .frame(height: 40)
                        .padding(.horizontal, 2)
                }

                if snapshot.budget != nil {
                    BudgetCard(snapshot: snapshot)
                }

                HStack(spacing: 8) {
                    PeriodTile(title: "Bu hafta",
                               value: snapshot.weekSpent,
                               net: snapshot.trackIncome ? snapshot.weekNet : nil,
                               snapshot: snapshot)
                    PeriodTile(title: "Bu ay",
                               value: snapshot.monthSpent,
                               net: snapshot.trackIncome ? snapshot.monthNet : nil,
                               snapshot: snapshot)
                }

                if !snapshot.recent.isEmpty {
                    RecentCard(snapshot: snapshot)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct HeroCard: View {
    let snapshot: BudgettSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bugün")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(snapshot.money(snapshot.todaySpent))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text("Günlük ortalama \(snapshot.money(snapshot.dailyAverage))")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .watchCard()
    }
}

private struct BudgetCard: View {
    let snapshot: BudgettSnapshot

    var body: some View {
        if let budget = snapshot.budget {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(budget.name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(snapshot.money(budget.remaining))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    Text(budget.daysLeft == 1 ? "1 gün kaldı" : "\(budget.daysLeft) gün kaldı")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                WatchArcGauge(progress: budget.progress, lineWidth: 7, tint: .primary)
                    .frame(width: 52, height: 52)
            }
            .watchCard()
        }
    }
}

private struct PeriodTile: View {
    let title: String
    let value: Decimal
    let net: Decimal?
    let snapshot: BudgettSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(snapshot.money(value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            if let net {
                Text("Net \(snapshot.money(net, signed: true))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .watchCard()
    }
}

private struct RecentCard: View {
    let snapshot: BudgettSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Son hareketler")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            ForEach(Array(snapshot.recent.prefix(3))) { entry in
                HStack(spacing: 8) {
                    WatchGlyph(symbol: entry.symbol, size: 18)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Text(entry.date, format: .dateTime.day().month(.abbreviated))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Text(snapshot.money(entry.amount, signed: entry.isIncome))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
            }
        }
        .watchCard()
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Veri yok")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Text("iPhone'da Budgett'ı aç, veriler saate aktarılsın.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
    }
}
