//
//  DataStore.swift
//  Budgett
//
//  Container creation, default content and first-run seeding.
//

import Foundation
import SwiftData

enum DataStore {
    static let schema = Schema([
        Txn.self, SpendCategory.self, Wallet.self,
        BudgetPlan.self, Recurrence.self, Goal.self
    ])

    /// Builds the container, falling back to a local store when CloudKit is not
    /// available (missing entitlement, signed-out iCloud account, …).
    static func makeContainer(cloud: Bool) -> ModelContainer {
        let cloudConfig = ModelConfiguration(
            "Budgett",
            schema: schema,
            cloudKitDatabase: cloud ? .automatic : .none
        )
        if let container = try? ModelContainer(for: schema, configurations: cloudConfig) {
            return container
        }
        let localConfig = ModelConfiguration("Budgett", schema: schema, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: localConfig) {
            return container
        }
        // Last resort: memory-only so the app still launches.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: memory)
    }

    // MARK: - Seeding

    static func bootstrap(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<SpendCategory>())) ?? 0
        guard existing == 0 else { return }

        for (index, seed) in defaultCategories.enumerated() {
            context.insert(SpendCategory(name: seed.name,
                                         symbol: seed.symbol,
                                         colorHex: seed.hex,
                                         kind: seed.kind,
                                         sortIndex: index))
        }

        let wallets = [
            Wallet(name: "Nakit", symbol: "banknote.fill", colorHex: "16C47F", type: .cash, sortIndex: 0),
            Wallet(name: "Banka Kartı", symbol: "building.columns.fill", colorHex: "3B5BFF", type: .bank, sortIndex: 1),
            Wallet(name: "Kredi Kartı", symbol: "creditcard.fill", colorHex: "8B5CF6", type: .card, sortIndex: 2)
        ]
        wallets.forEach { context.insert($0) }

        try? context.save()
    }

    struct CategorySeed {
        let name: String
        let symbol: String
        let hex: String
        let kind: CategoryKind
    }

    static let defaultCategories: [CategorySeed] = [
        .init(name: "Market", symbol: "cart.fill", hex: "FFA62B", kind: .expense),
        .init(name: "Yemek", symbol: "fork.knife", hex: "FF7A3D", kind: .expense),
        .init(name: "Kahve", symbol: "cup.and.saucer.fill", hex: "A0785A", kind: .expense),
        .init(name: "Ulaşım", symbol: "bus.fill", hex: "0A9CE0", kind: .expense),
        .init(name: "Akaryakıt", symbol: "fuelpump.fill", hex: "FF4D5E", kind: .expense),
        .init(name: "Kira", symbol: "house.fill", hex: "EC4899", kind: .expense),
        .init(name: "Faturalar", symbol: "bolt.fill", hex: "FFD23F", kind: .expense),
        .init(name: "Abonelikler", symbol: "arrow.trianglehead.2.clockwise.rotate.90", hex: "6C5CE7", kind: .expense),
        .init(name: "Alışveriş", symbol: "bag.fill", hex: "C56CF0", kind: .expense),
        .init(name: "Sağlık", symbol: "cross.case.fill", hex: "16C4B0", kind: .expense),
        .init(name: "Spor", symbol: "dumbbell.fill", hex: "5FD068", kind: .expense),
        .init(name: "Eğlence", symbol: "gamecontroller.fill", hex: "8B5CF6", kind: .expense),
        .init(name: "Eğitim", symbol: "graduationcap.fill", hex: "3B5BFF", kind: .expense),
        .init(name: "Seyahat", symbol: "airplane", hex: "0A9CE0", kind: .expense),
        .init(name: "Hediye", symbol: "gift.fill", hex: "FF6B9D", kind: .expense),
        .init(name: "Evcil Hayvan", symbol: "pawprint.fill", hex: "B7E048", kind: .expense),
        .init(name: "Maaş", symbol: "banknote.fill", hex: "16C47F", kind: .income),
        .init(name: "Ek Gelir", symbol: "briefcase.fill", hex: "16C4B0", kind: .income),
        .init(name: "Yatırım", symbol: "chart.line.uptrend.xyaxis", hex: "5FD068", kind: .income),
        .init(name: "İade", symbol: "arrow.uturn.left", hex: "7D8CA3", kind: .income)
    ]

    // MARK: - Demo content

    /// Generates two months of plausible activity so charts have something to say.
    static func loadDemoData(_ context: ModelContext) {
        bootstrap(context)
        let categories = (try? context.fetch(FetchDescriptor<SpendCategory>())) ?? []
        let wallets = (try? context.fetch(FetchDescriptor<Wallet>())) ?? []
        guard !categories.isEmpty else { return }

        func category(_ name: String) -> SpendCategory? { categories.first { $0.name == name } }

        let cal = Calendar.current
        let samples: [(String, String, Double, Int)] = [
            ("Market", "Haftalık market", 640, 2), ("Yemek", "Öğle yemeği", 185, 1),
            ("Kahve", "Filtre kahve", 95, 0), ("Ulaşım", "Toplu taşıma", 120, 3),
            ("Abonelikler", "Müzik aboneliği", 74.99, 5), ("Eğlence", "Sinema", 320, 6),
            ("Alışveriş", "Spor ayakkabı", 2450, 9), ("Market", "Manav", 310, 11),
            ("Yemek", "Akşam yemeği", 780, 12), ("Kahve", "Latte", 110, 13),
            ("Faturalar", "Elektrik", 890, 15), ("Ulaşım", "Taksi", 260, 16),
            ("Spor", "Salon üyeliği", 1200, 18), ("Sağlık", "Eczane", 430, 20),
            ("Market", "Haftalık alışveriş", 1180, 22), ("Yemek", "Fast food", 340, 23),
            ("Kahve", "Espresso", 85, 24), ("Seyahat", "Uçak bileti", 3200, 26),
            ("Hediye", "Doğum günü", 950, 28), ("Eğitim", "Online kurs", 640, 30),
            ("Market", "Market alışverişi", 720, 33), ("Yemek", "Akşam yemeği", 890, 35),
            ("Kahve", "Cold brew", 130, 36), ("Ulaşım", "Benzin", 1500, 38),
            ("Evcil Hayvan", "Mama", 480, 41), ("Alışveriş", "Kitap", 220, 44)
        ]

        for (categoryName, title, value, daysAgo) in samples {
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let hour = Int.random(in: 8...21)
            var jitteredDate = cal.date(byAdding: .hour, value: hour, to: date.startOfDay) ?? date
            if jitteredDate > .now { jitteredDate = .now.addingTimeInterval(-3_600) }
            let txn = Txn(amount: Decimal(value),
                          kind: .expense,
                          date: jitteredDate,
                          title: title,
                          category: category(categoryName),
                          wallet: wallets.randomElement())
            context.insert(txn)
        }

        for month in 0...1 {
            guard let date = cal.date(byAdding: .month, value: -month, to: .now) else { continue }
            var comps = cal.dateComponents([.year, .month], from: date)
            comps.day = 1
            comps.hour = 10
            if let payday = cal.date(from: comps) {
                context.insert(Txn(amount: 52_000, kind: .income, date: payday,
                                   title: "Maaş", category: category("Maaş"),
                                   wallet: wallets.first { $0.type == .bank }))
            }
        }

        let food = category("Yemek")?.id.uuidString
        let market = category("Market")?.id.uuidString
        let subs = category("Abonelikler")?.id.uuidString
        context.insert(BudgetPlan(name: "Aylık limit", symbol: "chart.pie.fill", colorHex: "3B5BFF",
                                  amount: 25_000, period: .month, sortIndex: 0))
        context.insert(BudgetPlan(name: "Mutfak", symbol: "fork.knife", colorHex: "FF7A3D",
                                  amount: 6_000, period: .month,
                                  categoryIDs: [food, market].compactMap { $0 }, sortIndex: 1))
        context.insert(BudgetPlan(name: "Abonelikler", symbol: "sparkles", colorHex: "6C5CE7",
                                  amount: 800, period: .month,
                                  categoryIDs: [subs].compactMap { $0 }, sortIndex: 2))

        context.insert(Goal(name: "Yaz tatili", symbol: "beach.umbrella.fill", colorHex: "0A9CE0",
                            target: 60_000, saved: 18_500,
                            deadline: cal.date(byAdding: .month, value: 5, to: .now)))
        context.insert(Goal(name: "Yeni laptop", symbol: "laptopcomputer", colorHex: "8B5CF6",
                            target: 90_000, saved: 32_000,
                            deadline: cal.date(byAdding: .month, value: 8, to: .now), sortIndex: 1))

        context.insert(Recurrence(title: "Müzik aboneliği", amount: Decimal(string: "74.99")!, kind: .expense,
                                  frequency: .monthly, categoryID: subs,
                                  startDate: cal.date(byAdding: .day, value: 4, to: .now) ?? .now,
                                  colorHex: "16C47F", symbol: "music.note"))
        context.insert(Recurrence(title: "Dizi & film", amount: 229, kind: .expense,
                                  frequency: .monthly, categoryID: subs,
                                  startDate: cal.date(byAdding: .day, value: 9, to: .now) ?? .now,
                                  colorHex: "FF4D5E", symbol: "film.fill"))
        context.insert(Recurrence(title: "Kira", amount: 18_000, kind: .expense,
                                  frequency: .monthly, categoryID: category("Kira")?.id.uuidString,
                                  startDate: cal.date(byAdding: .day, value: 12, to: .now) ?? .now,
                                  colorHex: "EC4899", symbol: "house.fill"))

        try? context.save()
    }

    static func eraseAll(_ context: ModelContext) {
        try? context.delete(model: Txn.self)
        try? context.delete(model: BudgetPlan.self)
        try? context.delete(model: Recurrence.self)
        try? context.delete(model: Goal.self)
        try? context.delete(model: Wallet.self)
        try? context.delete(model: SpendCategory.self)
        try? context.save()
    }

    static func eraseTransactions(_ context: ModelContext) {
        try? context.delete(model: Txn.self)
        try? context.save()
    }
}
