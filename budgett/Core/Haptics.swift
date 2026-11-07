//
//  Haptics.swift
//  Budgett
//

import UIKit

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard AppSettings.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
