//
//  FloatingTabBar.swift
//  Budgett
//

import SwiftUI

struct FloatingTabBar: View {
    @Binding var selection: AppTab
    var onAdd: () -> Void

    private let leading: [AppTab] = [.flow, .insights]
    private let trailing: [AppTab] = [.plans, .settings]

    var body: some View {
        HStack(spacing: 12) {
            group(leading)
            addButton
            group(trailing)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private func group(_ tabs: [AppTab]) -> some View {
        HStack(spacing: 2) {
            ForEach(tabs) { item($0) }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private func item(_ tab: AppTab) -> some View {
        let isActive = selection == tab
        return Button {
            guard selection != tab else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = tab }
            Haptics.tap(.soft)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolVariant(isActive ? .fill : .none)
                Text(tab.title)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isActive ? Color.primary : Color.secondary)
            .frame(width: 62, height: 44)
            .background {
                Capsule().fill(Color.primary.opacity(isActive ? 0.09 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isActive)
    }

    private var addButton: some View {
        Button {
            onAdd()
            Haptics.tap(.medium)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 62, height: 56)
                .background(Capsule().fill(Color.primary))
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Yeni işlem")
    }
}
