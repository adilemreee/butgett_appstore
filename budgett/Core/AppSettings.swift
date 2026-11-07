//
//  AppSettings.swift
//  Budgett
//
//  Observable, UserDefaults-backed preferences shared through the environment.
//

import SwiftUI
import Observation

enum KeypadStyle: String, CaseIterable, Identifiable, Codable {
    case simple, calculator
    var id: String { rawValue }
    var title: String { self == .simple ? "Sade" : "Hesap Makinesi" }
    var detail: String {
        self == .simple ? "Sadece rakamlar, tek dokunuşta kaydet" : "Toplama, çıkarma, çarpma ve bölme"
    }
}

enum CurrencyPresentation: String, CaseIterable, Identifiable, Codable {
    case symbol, code, none
    var id: String { rawValue }
    var title: String {
        switch self {
        case .symbol: "Sembol (₺)"
        case .code: "Kod (TRY)"
        case .none: "Gizle"
        }
    }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let store = UserDefaults.standard

    // MARK: Appearance
    var appearance: AppearanceMode { didSet { store.set(appearance.rawValue, forKey: Keys.appearance) } }
    var accent: ThemeAccent { didSet { store.set(accent.rawValue, forKey: Keys.accent) } }
    var privacyMode: Bool { didSet { store.set(privacyMode, forKey: Keys.privacyMode) } }

    // MARK: Money
    var currencyCode: String { didSet { store.set(currencyCode, forKey: Keys.currencyCode) } }
    var currencyPresentation: CurrencyPresentation { didSet { store.set(currencyPresentation.rawValue, forKey: Keys.currencyPresentation) } }
    var showCents: Bool { didSet { store.set(showCents, forKey: Keys.showCents) } }
    var trackIncome: Bool { didSet { store.set(trackIncome, forKey: Keys.trackIncome) } }

    // MARK: Behaviour
    var firstWeekday: Int { didSet { store.set(firstWeekday, forKey: Keys.firstWeekday) } }
    var keypadStyle: KeypadStyle { didSet { store.set(keypadStyle.rawValue, forKey: Keys.keypadStyle) } }
    var hapticsEnabled: Bool { didSet { store.set(hapticsEnabled, forKey: Keys.haptics) } }
    var biometricLock: Bool { didSet { store.set(biometricLock, forKey: Keys.biometricLock) } }
    var defaultPeriod: Period { didSet { store.set(defaultPeriod.rawValue, forKey: Keys.defaultPeriod) } }
    var carryUpcoming: Bool { didSet { store.set(carryUpcoming, forKey: Keys.carryUpcoming) } }

    // MARK: Notifications
    var budgetAlerts: Bool { didSet { store.set(budgetAlerts, forKey: Keys.budgetAlerts) } }
    var billAlerts: Bool { didSet { store.set(billAlerts, forKey: Keys.billAlerts) } }
    var dailyReminder: Bool { didSet { store.set(dailyReminder, forKey: Keys.dailyReminder) } }
    var reminderHour: Int { didSet { store.set(reminderHour, forKey: Keys.reminderHour) } }
    var reminderMinute: Int { didSet { store.set(reminderMinute, forKey: Keys.reminderMinute) } }

    // MARK: Data
    var iCloudSync: Bool { didSet { store.set(iCloudSync, forKey: Keys.iCloudSync) } }

    private init() {
        let d = UserDefaults.standard
        appearance = AppearanceMode(rawValue: d.string(forKey: Keys.appearance) ?? "") ?? .system
        accent = ThemeAccent(rawValue: d.string(forKey: Keys.accent) ?? "") ?? .mono
        privacyMode = d.bool(forKey: Keys.privacyMode)

        currencyCode = d.string(forKey: Keys.currencyCode) ?? (Locale.current.currency?.identifier ?? "TRY")
        currencyPresentation = CurrencyPresentation(rawValue: d.string(forKey: Keys.currencyPresentation) ?? "") ?? .symbol
        showCents = d.object(forKey: Keys.showCents) as? Bool ?? true
        trackIncome = d.object(forKey: Keys.trackIncome) as? Bool ?? true

        firstWeekday = d.object(forKey: Keys.firstWeekday) as? Int ?? Calendar.current.firstWeekday
        keypadStyle = KeypadStyle(rawValue: d.string(forKey: Keys.keypadStyle) ?? "") ?? .calculator
        hapticsEnabled = d.object(forKey: Keys.haptics) as? Bool ?? true
        biometricLock = d.bool(forKey: Keys.biometricLock)
        defaultPeriod = Period(rawValue: d.string(forKey: Keys.defaultPeriod) ?? "") ?? .month
        carryUpcoming = d.object(forKey: Keys.carryUpcoming) as? Bool ?? true

        budgetAlerts = d.object(forKey: Keys.budgetAlerts) as? Bool ?? false
        billAlerts = d.object(forKey: Keys.billAlerts) as? Bool ?? false
        dailyReminder = d.bool(forKey: Keys.dailyReminder)
        reminderHour = d.object(forKey: Keys.reminderHour) as? Int ?? 21
        reminderMinute = d.object(forKey: Keys.reminderMinute) as? Int ?? 0

        iCloudSync = d.bool(forKey: Keys.iCloudSync)
    }

    /// Calendar honouring the user's chosen first day of week.
    var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = firstWeekday
        return c
    }

    var currencySymbol: String {
        Money.symbol(for: currencyCode)
    }

    func resetPreferences() {
        for key in Keys.all { store.removeObject(forKey: key) }
        appearance = .system
        accent = .mono
        privacyMode = false
        currencyCode = Locale.current.currency?.identifier ?? "TRY"
        currencyPresentation = .symbol
        showCents = true
        trackIncome = true
        firstWeekday = Calendar.current.firstWeekday
        keypadStyle = .calculator
        hapticsEnabled = true
        biometricLock = false
        defaultPeriod = .month
        carryUpcoming = true
        budgetAlerts = false
        billAlerts = false
        dailyReminder = false
        reminderHour = 21
        reminderMinute = 0
        iCloudSync = false
    }

    private enum Keys {
        static let appearance = "settings.appearance"
        static let accent = "settings.accent"
        static let privacyMode = "settings.privacyMode"
        static let currencyCode = "settings.currencyCode"
        static let currencyPresentation = "settings.currencyPresentation"
        static let showCents = "settings.showCents"
        static let trackIncome = "settings.trackIncome"
        static let firstWeekday = "settings.firstWeekday"
        static let keypadStyle = "settings.keypadStyle"
        static let haptics = "settings.haptics"
        static let biometricLock = "settings.biometricLock"
        static let defaultPeriod = "settings.defaultPeriod"
        static let carryUpcoming = "settings.carryUpcoming"
        static let budgetAlerts = "settings.budgetAlerts"
        static let billAlerts = "settings.billAlerts"
        static let dailyReminder = "settings.dailyReminder"
        static let reminderHour = "settings.reminderHour"
        static let reminderMinute = "settings.reminderMinute"
        static let iCloudSync = "settings.iCloudSync"

        static var all: [String] {
            [appearance, accent, privacyMode, currencyCode, currencyPresentation, showCents,
             trackIncome, firstWeekday, keypadStyle, haptics, biometricLock, defaultPeriod,
             carryUpcoming, budgetAlerts, billAlerts, dailyReminder, reminderHour,
             reminderMinute, iCloudSync]
        }
    }
}

// MARK: - Environment plumbing

extension EnvironmentValues {
    @Entry var settings: AppSettings = .shared
}
