//
//  CategoryEditor.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct CategoryEditor: View {
    var category: SpendCategory?
    var defaultKind: CategoryKind = .expense
    var onSave: ((SpendCategory) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var categories: [SpendCategory]

    @State private var name = ""
    @State private var symbol = "tag.fill"
    @State private var colorHex = "3B5BFF"
    @State private var kind: CategoryKind = .expense

    private var tint: Color { Color(hex: colorHex) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        CategoryBadge(symbol: symbol, color: tint, size: 74)
                        TextField("Kategori adı", text: $name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color.primary.opacity(0.06), in: Capsule())
                            .frame(maxWidth: 280)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Tür")
                        Picker("Tür", selection: $kind) {
                            ForEach(CategoryKind.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Simge")
                        SymbolGrid(symbols: Palette.categorySymbols, selection: $symbol, tint: .primary)
                    }
                }
                .padding(Metrics.hPadding)
                .padding(.bottom, 30)
            }
            .background(AuroraBackground(accent: AppSettings.shared.accent))
            .navigationTitle(category == nil ? "Yeni kategori" : "Kategoriyi düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let category else {
            kind = defaultKind
            colorHex = ThemeAccent.mono.hex
            return
        }
        name = category.name
        symbol = category.symbol
        colorHex = category.colorHex
        kind = category.kind
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let target: SpendCategory
        if let category {
            target = category
        } else {
            target = SpendCategory(name: trimmed, symbol: symbol, colorHex: colorHex, kind: kind,
                                   sortIndex: (categories.map(\.sortIndex).max() ?? 0) + 1)
            context.insert(target)
        }
        target.name = trimmed
        target.symbol = symbol
        target.colorHex = colorHex
        target.kind = kind
        try? context.save()
        Haptics.success()
        onSave?(target)
        dismiss()
    }
}
