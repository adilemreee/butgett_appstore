//
//  BudgettWidgetsBundle.swift
//  BudgettWidgets
//

import WidgetKit
import SwiftUI

@main
struct BudgettWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SpendingWidget()
        BudgetGaugeWidget()
        RecentActivityWidget()
        UpcomingBillsWidget()
        QuickAddControl()
    }
}
