//
//  Exporter.swift
//  Budgett
//
//  CSV + JSON backup writers. Files land in the temp directory and are handed
//  to the share sheet.
//

import Foundation
import SwiftData

enum Exporter {

    static func csv(_ txns: [Txn], settings: AppSettings) -> String {
        var lines = ["Tarih,Saat,Tür,Başlık,Kategori,Cüzdan,Tutar,Para Birimi,Etiketler,Not"]
        let sorted = txns.sorted { $0.date > $1.date }
        for txn in sorted {
            let fields = [
                txn.date.formatted(.iso8601.year().month().day().dateSeparator(.dash)),
                txn.date.formatted(date: .omitted, time: .shortened),
                txn.kind.title,
                txn.displayTitle,
                txn.category?.name ?? "",
                txn.wallet?.name ?? "",
                Money.number(txn.amount, showCents: true),
                txn.currencyCode.isEmpty ? settings.currencyCode : txn.currencyCode,
                txn.tags.joined(separator: " "),
                txn.note
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private nonisolated static func escape(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: "\"", with: "\"\"")
        if cleaned.contains(",") || cleaned.contains("\n") || cleaned.contains("\"") {
            return "\"\(cleaned)\""
        }
        return cleaned
    }

    static func write(_ contents: String, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    static func exportCSV(_ txns: [Txn], settings: AppSettings) -> URL? {
        let stamp = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        return write(csv(txns, settings: settings), name: "budgett-\(stamp).csv")
    }

    // MARK: - JSON backup

    struct Backup: Codable {
        struct TxnDTO: Codable {
            var amount: Decimal
            var kind: String
            var date: Date
            var title: String
            var note: String
            var category: String?
            var wallet: String?
            var tags: [String]
            var currency: String
        }
        var version: Int = 1
        var exportedAt: Date = .now
        var transactions: [TxnDTO] = []
    }

    static func exportJSON(_ txns: [Txn]) -> URL? {
        var backup = Backup()
        backup.transactions = txns.map {
            Backup.TxnDTO(amount: $0.amount, kind: $0.kindRaw, date: $0.date,
                          title: $0.title, note: $0.note,
                          category: $0.category?.name, wallet: $0.wallet?.name,
                          tags: $0.tags, currency: $0.currencyCode)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(backup),
              let string = String(data: data, encoding: .utf8) else { return nil }
        let stamp = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        return write(string, name: "budgett-yedek-\(stamp).json")
    }
}
