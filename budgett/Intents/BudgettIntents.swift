//
//  BudgettIntents.swift
//  Budgett
//
//  Siri & Shortcuts support: log an expense without opening the app.
//

import AppIntents
import SwiftData
import Foundation

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Harcama ekle"
    static var description = IntentDescription("Budgett'e hızlıca yeni bir harcama kaydeder.")

    @Parameter(title: "Tutar", requestValueDialog: "Ne kadar harcadın?")
    var amount: Double

    @Parameter(title: "Açıklama", requestValueDialog: "Ne için?")
    var note: String?

    @Parameter(title: "Kategori")
    var categoryName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$amount) tutarında harcama ekle: \(\.$note)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = DataStore.makeContainer(cloud: AppSettings.shared.iCloudSync)
        let context = ModelContext(container)

        let categories = (try? context.fetch(FetchDescriptor<SpendCategory>())) ?? []
        let match = categoryName.flatMap { name in
            categories.first { $0.name.localizedCaseInsensitiveContains(name) }
        }

        let txn = Txn(amount: Decimal(amount),
                      kind: .expense,
                      date: .now,
                      title: note ?? "",
                      category: match)
        context.insert(txn)
        try? context.save()

        let formatted = Money.string(Decimal(amount), settings: AppSettings.shared)
        return .result(dialog: IntentDialog("\(formatted) harcama kaydedildi."))
    }
}

struct CheckBalanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Bu ay ne kadar harcadım"
    static var description = IntentDescription("Bu ayki toplam harcamanı söyler.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = DataStore.makeContainer(cloud: AppSettings.shared.iCloudSync)
        let context = ModelContext(container)
        let settings = AppSettings.shared
        let interval = PeriodCursor(period: .month, anchor: .now).interval(settings.calendar)
        let txns = (try? context.fetch(FetchDescriptor<Txn>())) ?? []
        let stats = InsightsEngine.stats(txns.filter { interval.contains($0.date) }, interval: interval)
        let total = Money.string(stats.expense, settings: settings)
        return .result(dialog: IntentDialog("Bu ay \(total) harcadın."))
    }
}

struct BudgettShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: ["\(.applicationName)'e harcama ekle", "\(.applicationName) ile harcama kaydet"],
            shortTitle: "Harcama ekle",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: CheckBalanceIntent(),
            phrases: ["\(.applicationName) bu ay ne kadar harcadım"],
            shortTitle: "Aylık harcama",
            systemImageName: "chart.bar.fill"
        )
    }
}
