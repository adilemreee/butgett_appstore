//
//  PeriodNavigator.swift
//  Budgett
//

import SwiftUI

struct PeriodNavigator: View {
    @Binding var cursor: PeriodCursor
    @Environment(\.settings) private var settings

    var body: some View {
        HStack(spacing: 8) {
            stepButton(-1, symbol: "chevron.left", enabled: cursor.period != .all)

            Menu {
                Picker("Dönem", selection: Binding(
                    get: { cursor.period },
                    set: { newValue in
                        withAnimation(.smooth) {
                            cursor = PeriodCursor(period: newValue, anchor: .now)
                        }
                        Haptics.selection()
                    })) {
                        ForEach(Period.allCases) { period in
                            Label(period.title, systemImage: symbol(for: period)).tag(period)
                        }
                    }
                if !cursor.isCurrent {
                    Divider()
                    Button("Bugüne dön", systemImage: "arrow.uturn.backward") {
                        withAnimation(.smooth) { cursor.anchor = .now }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(cursor.title(settings.calendar))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)

            stepButton(1, symbol: "chevron.right", enabled: cursor.canStepForward(settings.calendar))
        }
        .padding(.horizontal, 6)
        .background(.quaternary.opacity(0.45), in: Capsule())
    }

    private func symbol(for period: Period) -> String {
        switch period {
        case .day: "sun.max"
        case .week: "calendar.day.timeline.left"
        case .month: "calendar"
        case .year: "calendar.badge.clock"
        case .all: "infinity"
        }
    }

    private func stepButton(_ direction: Int, symbol: String, enabled: Bool) -> some View {
        Button {
            withAnimation(.smooth) { cursor.step(direction, cal: settings.calendar) }
            Haptics.tap(.soft)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.35))
        .disabled(!enabled)
    }
}
