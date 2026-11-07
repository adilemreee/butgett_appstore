//
//  FilterSheet.swift
//  Budgett
//

import SwiftUI

struct FilterSheet: View {
    @Binding var filter: TxnFilter
    var categories: [SpendCategory]
    var wallets: [Wallet]
    var tags: [String]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.settings) private var settings
    @State private var minText = ""
    @State private var maxText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Tür") {
                    HStack(spacing: 8) {
                        ForEach(TxnKind.allCases) { kind in
                            let on = filter.kinds.contains(kind)
                            Button {
                                if on { filter.kinds.remove(kind) } else { filter.kinds.insert(kind) }
                                Haptics.selection()
                            } label: {
                                Label(kind.title, systemImage: kind.symbol)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(on ? kind.color.opacity(0.18) : Color.secondary.opacity(0.08),
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundStyle(on ? kind.color : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Kategoriler") {
                    ChipFlow(items: categories.map {
                        ChipItem(id: $0.id.uuidString, title: $0.name, colorHex: $0.colorHex, symbol: $0.symbol)
                    }, selection: $filter.categoryIDs)
                }

                if !wallets.isEmpty {
                    Section("Cüzdanlar") {
                        ChipFlow(items: wallets.map {
                            ChipItem(id: $0.id.uuidString, title: $0.name, colorHex: $0.colorHex, symbol: $0.symbol)
                        }, selection: $filter.walletIDs)
                    }
                }

                if !tags.isEmpty {
                    Section("Etiketler") {
                        ChipFlow(items: tags.map {
                            ChipItem(id: $0, title: "#\($0)", colorHex: settings.accent.hex, symbol: "number")
                        }, selection: $filter.tags)
                    }
                }

                Section("Tutar aralığı") {
                    HStack {
                        TextField("En az", text: $minText)
                            .keyboardType(.decimalPad)
                        Text("–").foregroundStyle(.secondary)
                        TextField("En çok", text: $maxText)
                            .keyboardType(.decimalPad)
                    }
                    .font(.system(size: 15, design: .rounded))
                }

                Section {
                    Toggle("Analiz dışı kayıtları gizle", isOn: $filter.hideExcluded)
                        .tint(Palette.controlTint)
                }

                Section {
                    Button("Filtreleri temizle", role: .destructive) {
                        filter.reset()
                        minText = ""
                        maxText = ""
                        Haptics.tap()
                    }
                    .disabled(!filter.isActive)
                }
            }
            .navigationTitle("Filtrele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") {
                        filter.minAmount = minText.isEmpty ? nil : Money.decimal(from: minText)
                        filter.maxAmount = maxText.isEmpty ? nil : Money.decimal(from: maxText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let min = filter.minAmount { minText = Money.number(min) }
                if let max = filter.maxAmount { maxText = Money.number(max) }
            }
        }
        .presentationDetents([.large])
    }
}

struct ChipItem: Identifiable, Hashable {
    let id: String
    let title: String
    let colorHex: String
    let symbol: String

    var color: Color { Color(hex: colorHex) }
}

/// Wrapping multi-select chips used across filter and picker sheets.
struct ChipFlow: View {
    var items: [ChipItem]
    @Binding var selection: Set<String>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items) { item in
                let on = selection.contains(item.id)
                Button {
                    if on { selection.remove(item.id) } else { selection.insert(item.id) }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 10, weight: .bold))
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(on ? item.color.opacity(0.22) : Color.secondary.opacity(0.10), in: Capsule())
                    .foregroundStyle(on ? item.color : .secondary)
                    .overlay {
                        Capsule().strokeBorder(on ? item.color.opacity(0.5) : .clear, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Minimal flow layout so chips wrap naturally inside forms.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: CGFloat = 1
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                totalHeight += rowHeight + spacing
                rows += 1
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
