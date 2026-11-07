//
//  TxnFilter.swift
//  Budgett
//

import Foundation

struct TxnFilter: Equatable {
    var kinds: Set<TxnKind> = []
    var categoryIDs: Set<String> = []
    var walletIDs: Set<String> = []
    var tags: Set<String> = []
    var minAmount: Decimal?
    var maxAmount: Decimal?
    var hideExcluded: Bool = false

    var isActive: Bool {
        !kinds.isEmpty || !categoryIDs.isEmpty || !walletIDs.isEmpty || !tags.isEmpty
            || minAmount != nil || maxAmount != nil || hideExcluded
    }

    var badgeCount: Int {
        var count = 0
        if !kinds.isEmpty { count += 1 }
        if !categoryIDs.isEmpty { count += 1 }
        if !walletIDs.isEmpty { count += 1 }
        if !tags.isEmpty { count += 1 }
        if minAmount != nil || maxAmount != nil { count += 1 }
        if hideExcluded { count += 1 }
        return count
    }

    mutating func reset() { self = TxnFilter() }

    func matches(_ txn: Txn) -> Bool {
        if !kinds.isEmpty && !kinds.contains(txn.kind) { return false }
        if !categoryIDs.isEmpty {
            guard let id = txn.category?.id.uuidString, categoryIDs.contains(id) else { return false }
        }
        if !walletIDs.isEmpty {
            guard let id = txn.wallet?.id.uuidString, walletIDs.contains(id) else { return false }
        }
        if !tags.isEmpty && tags.isDisjoint(with: Set(txn.tags)) { return false }
        if let min = minAmount, txn.amount < min { return false }
        if let max = maxAmount, txn.amount > max { return false }
        if hideExcluded && txn.isExcluded { return false }
        return true
    }

    func matches(search: String, _ txn: Txn) -> Bool {
        guard !search.isEmpty else { return true }
        let needle = search.lowercased()
        if txn.displayTitle.lowercased().contains(needle) { return true }
        if txn.note.lowercased().contains(needle) { return true }
        if let name = txn.category?.name.lowercased(), name.contains(needle) { return true }
        if let name = txn.wallet?.name.lowercased(), name.contains(needle) { return true }
        if txn.tags.contains(where: { $0.lowercased().contains(needle) }) { return true }
        if Money.number(txn.amount).contains(needle) { return true }
        return false
    }
}
