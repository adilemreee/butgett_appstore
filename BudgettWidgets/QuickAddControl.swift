//
//  QuickAddControl.swift
//  BudgettWidgets
//
//  Control Center / Lock Screen button that jumps straight into capture.
//

import AppIntents
import SwiftUI
import WidgetKit

struct OpenQuickEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Hızlı harcama gir"
    static var description = IntentDescription("Budgett'i açıp yeni işlem ekranına gider.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // Runs in the app process; the flag is picked up on the next activation.
        SharedStore.defaults.set(true, forKey: SharedStore.pendingEntryKey)
        UserDefaults.standard.set(true, forKey: SharedStore.pendingEntryKey)
        return .result()
    }
}

struct QuickAddControl: ControlWidget {
    let kind = "BudgettQuickAdd"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenQuickEntryIntent()) {
                Label("Harcama ekle", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Harcama ekle")
        .description("Tek dokunuşla yeni işlem.")
    }
}
