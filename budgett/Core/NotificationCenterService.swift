//
//  NotificationCenterService.swift
//  Budgett
//

import Foundation
import UserNotifications

enum Notifier {
    private static let dailyID = "budgett.daily.reminder"
    private static let billPrefix = "budgett.bill."

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func syncDailyReminder(settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])
        guard settings.dailyReminder else { return }
        guard await requestAuthorization() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bugünü kaydettin mi?"
        content.body = "Harcamalarını eklemek 10 saniye sürer."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = settings.reminderHour
        comps.minute = settings.reminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger))
    }

    static func syncBillReminders(_ bills: [UpcomingBill], settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map(\.identifier).filter { $0.hasPrefix(billPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        guard settings.billAlerts else { return }
        guard await requestAuthorization() else { return }

        let cal = Calendar.current
        for bill in bills.prefix(20) {
            guard let fireDate = cal.date(byAdding: .day, value: -1, to: bill.date),
                  fireDate > .now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Yarın: \(bill.rule.title)"
            content.body = Money.string(bill.rule.amount, settings: settings) + " ödemesi yaklaşıyor."
            content.sound = .default

            var comps = cal.dateComponents([.year, .month, .day], from: fireDate)
            comps.hour = 10
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            try? await center.add(UNNotificationRequest(
                identifier: billPrefix + bill.rule.id.uuidString,
                content: content, trigger: trigger))
        }
    }

    static func budgetAlert(name: String, percent: Int, remaining: String) async {
        guard AppSettings.shared.budgetAlerts else { return }
        guard await requestAuthorization() else { return }
        let content = UNMutableNotificationContent()
        content.title = percent >= 100 ? "\(name) bütçesi aşıldı" : "\(name) bütçesinin %\(percent)'i bitti"
        content.body = percent >= 100 ? "Limitin üzerindesin." : "Kalan: \(remaining)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
