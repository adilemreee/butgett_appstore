//
//  WidgetBridge.swift
//  Shared — bu klasör hem "budgett" hem "BudgettWidgetsExtension" hedefinin üyesi.
//  Buraya eklenen her dosya iki hedefte de derlenir.
//
//  Widgets never touch the SwiftData store. The app publishes a small JSON
//  snapshot into the shared App Group container and the extension reads it.
//  That keeps the widget cheap, avoids a second CloudKit stack, and means the
//  main store can stay exactly where it is.
//

import Foundation

// MARK: - Shared container

enum SharedStore {
    /// Must match the App Group enabled on BOTH targets in
    /// Xcode ▸ Signing & Capabilities. Change it in this one place.
    static let appGroupID = "group.adilemre.budgett"

    static let snapshotFile = "widget-snapshot.json"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var snapshotURL: URL? {
        containerURL?.appendingPathComponent(snapshotFile)
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// Set by the Control Center button / widget so the app can jump straight
    /// into the capture sheet on next launch.
    static let pendingEntryKey = "budgett.pendingQuickEntry"

    static func load() -> BudgettSnapshot? {
        guard let url = snapshotURL, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BudgettSnapshot.self, from: data)
    }

    @discardableResult
    static func save(_ snapshot: BudgettSnapshot) -> Bool {
        guard let url = snapshotURL else { return false }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    static func encode(_ snapshot: BudgettSnapshot) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(snapshot)
    }

    static func decode(_ data: Data) -> BudgettSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BudgettSnapshot.self, from: data)
    }

    static func encodeTxn(_ txn: WatchTxnRequest) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(txn)
    }

    static func decodeTxn(_ data: Data) -> WatchTxnRequest? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WatchTxnRequest.self, from: data)
    }
}

// MARK: - Watch hand-off

/// The app-group container is a separate filesystem on each device — the phone
/// writing `widget-snapshot.json` never makes it appear on the watch by itself.
/// The phone therefore pushes the encoded snapshot over WatchConnectivity, and
/// the watch stores it locally. Both sides agree on these keys.
enum WatchSync {
    nonisolated static let snapshotKey = "budgett.watch.snapshot"
    nonisolated static let addTxnKey = "budgett.watch.addTxn"
}

/// A quick expense/income captured on the watch and sent back to the phone.
struct WatchTxnRequest: Codable, Equatable {
    var amount: Decimal
    var isIncome: Bool
    var date: Date
}

// MARK: - Snapshot

struct BudgettSnapshot: Codable, Equatable {

    struct Day: Codable, Equatable, Identifiable {
        var date: Date
        var amount: Decimal
        var id: Date { date }
    }

    struct Slice: Codable, Equatable, Identifiable {
        var name: String
        var colorHex: String
        var symbol: String
        var amount: Decimal
        var share: Double
        var id: String { name }
    }

    struct Entry: Codable, Equatable, Identifiable {
        var title: String
        var amount: Decimal
        var isIncome: Bool
        var colorHex: String
        var symbol: String
        var date: Date
        var id: String { "\(title)-\(date.timeIntervalSince1970)" }
    }

    struct Budget: Codable, Equatable {
        var name: String
        var symbol: String
        var colorHex: String
        var limit: Decimal
        var spent: Decimal
        var periodLabel: String
        var daysLeft: Int
        var dailyAllowance: Decimal

        var remaining: Decimal { limit - spent }
        var isOver: Bool { spent > limit }
        var progress: Double {
            guard limit > 0 else { return 0 }
            return max(0, min(1.4, decimalToDouble(spent / limit)))
        }
    }

    struct Bill: Codable, Equatable, Identifiable {
        var title: String
        var amount: Decimal
        var date: Date
        var colorHex: String
        var symbol: String
        var id: String { "\(title)-\(date.timeIntervalSince1970)" }

        var daysAway: Int {
            max(0, Calendar.current.dateComponents([.day],
                                                   from: Calendar.current.startOfDay(for: .now),
                                                   to: Calendar.current.startOfDay(for: date)).day ?? 0)
        }

        var relativeTitle: String {
            switch daysAway {
            case 0: "Bugün"
            case 1: "Yarın"
            default: "\(daysAway) gün"
            }
        }
    }

    var updatedAt: Date = .now
    var currencyCode: String = "TRY"
    var showCents: Bool = true
    var privacyMode: Bool = false
    var trackIncome: Bool = true
    var accentHex: String = "3B5BFF"

    var todaySpent: Decimal = 0
    var weekSpent: Decimal = 0
    var weekIncome: Decimal = 0
    var monthSpent: Decimal = 0
    var monthIncome: Decimal = 0
    var dailyAverage: Decimal = 0
    var netWorth: Decimal = 0
    var noSpendStreak: Int = 0

    var days: [Day] = []
    var categories: [Slice] = []
    var recent: [Entry] = []
    var budget: Budget?
    var bills: [Bill] = []

    var weekNet: Decimal { weekIncome - weekSpent }
    var monthNet: Decimal { monthIncome - monthSpent }
}

// MARK: - Formatting shared by both targets

func decimalToDouble(_ value: Decimal) -> Double {
    NSDecimalNumber(decimal: value).doubleValue
}

extension BudgettSnapshot {

    var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return (formatter.currencySymbol ?? currencyCode).trimmingCharacters(in: .whitespaces)
    }

    /// `₺ 1.234,50` — mirrors the in-app presentation rules.
    func money(_ value: Decimal, cents: Bool? = nil, signed: Bool = false, unit: Bool = true) -> String {
        let useCents = cents ?? showCents
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = useCents ? 2 : 0
        formatter.maximumFractionDigits = useCents ? 2 : 0

        let digits = privacyMode
            ? "••••"
            : (formatter.string(from: NSDecimalNumber(decimal: abs(value))) ?? "0")

        var prefix = ""
        if signed { prefix = value < 0 ? "-" : "+" }
        let head = unit ? "\(prefix)\(currencySymbol) " : prefix
        return head + digits
    }

    /// Compact form for axis labels: 1,2B
    func compact(_ value: Decimal) -> String {
        let number = abs(decimalToDouble(value))
        switch number {
        case 1_000_000...: return String(format: "%.1fM", number / 1_000_000)
        case 10_000...: return String(format: "%.0fB", number / 1_000)
        case 1_000...: return String(format: "%.1fB", number / 1_000)
        default: return String(format: "%.0f", number)
        }
    }

    var isStale: Bool { Date.now.timeIntervalSince(updatedAt) > 6 * 3600 }
}

// MARK: - Placeholder used by previews and the widget gallery

extension BudgettSnapshot {
    static var placeholder: BudgettSnapshot {
        let cal = Calendar.current
        var snapshot = BudgettSnapshot()
        snapshot.todaySpent = 340
        snapshot.weekSpent = 2_480
        snapshot.weekIncome = 12_000
        snapshot.monthSpent = 7_770
        snapshot.monthIncome = 52_000
        snapshot.dailyAverage = 370
        snapshot.netWorth = 85_800
        snapshot.noSpendStreak = 0
        snapshot.days = (0..<7).reversed().map { offset in
            Day(date: cal.date(byAdding: .day, value: -offset, to: .now) ?? .now,
                amount: Decimal([180, 640, 0, 320, 910, 240, 340][6 - offset]))
        }
        snapshot.categories = [
            Slice(name: "Market", colorHex: "FFA62B", symbol: "cart.fill", amount: 2_250, share: 0.29),
            Slice(name: "Yemek", colorHex: "FF7A3D", symbol: "fork.knife", amount: 1_890, share: 0.24),
            Slice(name: "Ulaşım", colorHex: "0A9CE0", symbol: "bus.fill", amount: 1_380, share: 0.18),
            Slice(name: "Eğlence", colorHex: "8B5CF6", symbol: "gamecontroller.fill", amount: 960, share: 0.12)
        ]
        snapshot.recent = [
            Entry(title: "Migros", amount: 640, isIncome: false, colorHex: "FFA62B",
                  symbol: "cart.fill", date: .now.addingTimeInterval(-3_600)),
            Entry(title: "Filtre kahve", amount: 95, isIncome: false, colorHex: "A0785A",
                  symbol: "cup.and.saucer.fill", date: .now.addingTimeInterval(-9_000)),
            Entry(title: "Maaş", amount: 52_000, isIncome: true, colorHex: "16C47F",
                  symbol: "banknote.fill", date: .now.addingTimeInterval(-86_400)),
            Entry(title: "İstanbulkart", amount: 120, isIncome: false, colorHex: "0A9CE0",
                  symbol: "bus.fill", date: .now.addingTimeInterval(-172_800))
        ]
        snapshot.budget = Budget(name: "Aylık limit", symbol: "chart.pie.fill", colorHex: "3B5BFF",
                                 limit: 25_000, spent: 7_865, periodLabel: "bu ay",
                                 daysLeft: 10, dailyAllowance: 1_714)
        snapshot.bills = [
            Bill(title: "Spotify", amount: Decimal(string: "74.99")!,
                 date: .now.addingTimeInterval(4 * 86_400), colorHex: "16C47F", symbol: "music.note"),
            Bill(title: "Netflix", amount: 229, date: .now.addingTimeInterval(9 * 86_400),
                 colorHex: "FF4D5E", symbol: "film.fill"),
            Bill(title: "Kira", amount: 18_000, date: .now.addingTimeInterval(12 * 86_400),
                 colorHex: "EC4899", symbol: "house.fill")
        ]
        return snapshot
    }
}

// MARK: - Deep links

enum BudgettLink {
    static let scheme = "budgett"

    static var newExpense: URL { URL(string: "\(scheme)://new?kind=expense")! }
    static var newIncome: URL { URL(string: "\(scheme)://new?kind=income")! }
    static func tab(_ name: String) -> URL { URL(string: "\(scheme)://open?tab=\(name)")! }
}
