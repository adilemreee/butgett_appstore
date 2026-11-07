//
//  AppRouter.swift
//  Budgett
//

import SwiftUI
import Observation

enum AppTab: Int, CaseIterable, Identifiable {
    case flow, insights, plans, settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .flow: "Akış"
        case .insights: "Analiz"
        case .plans: "Planlar"
        case .settings: "Ayarlar"
        }
    }

    var symbol: String {
        switch self {
        case .flow: "list.bullet.rectangle.fill"
        case .insights: "chart.bar.xaxis"
        case .plans: "square.grid.2x2.fill"
        case .settings: "gearshape.fill"
        }
    }
}

@Observable
final class AppRouter {
    var tab: AppTab = .flow
    var showQuickEntry = false
    var quickEntryKind: TxnKind = .expense
    var editingTxn: Txn?
    var showSearch = false

    func newTransaction(kind: TxnKind = .expense) {
        editingTxn = nil
        quickEntryKind = kind
        showQuickEntry = true
    }

    func edit(_ txn: Txn) {
        editingTxn = txn
        quickEntryKind = txn.kind
        showQuickEntry = true
    }
}
