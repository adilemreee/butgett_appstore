//
//  WidgetBackgrounds.swift
//  BudgettWidgets
//

import SwiftUI
import WidgetKit

extension View {
    /// Accessory families render on the Lock Screen where a custom background
    /// is not wanted; system families get a soft accent wash.
    @ViewBuilder
    func budgettContainer(_ family: WidgetFamily, accent: Color) -> some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            self.containerBackground(.clear, for: .widget)
        default:
            self.containerBackground(Color(.systemBackground), for: .widget)
        }
    }
}
