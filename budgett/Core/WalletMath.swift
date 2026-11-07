//
//  WalletMath.swift
//  Budgett
//

import Foundation

extension Wallet {
    /// Running balance derived from the opening balance plus every movement.
    func balance(from txns: [Txn]) -> Decimal {
        var total = openingBalance
        for txn in txns {
            if txn.wallet?.id == id {
                switch txn.kind {
                case .income: total += txn.amount
                case .expense, .transfer: total -= txn.amount
                }
            } else if txn.kind == .transfer, txn.toWalletID == id {
                total += txn.amount
            }
        }
        return total
    }

    func movementCount(in txns: [Txn]) -> Int {
        txns.filter { $0.wallet?.id == id || $0.toWalletID == id }.count
    }
}

enum NetWorth {
    static func total(wallets: [Wallet], txns: [Txn]) -> Decimal {
        wallets
            .filter { $0.includeInNetWorth && !$0.isArchived }
            .reduce(Decimal(0)) { $0 + $1.balance(from: txns) }
    }
}
