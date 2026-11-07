//
//  CategoriesScreen.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct CategoriesScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings
    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]
    @Query private var txns: [Txn]

    @State private var editing: SpendCategory?
    @State private var showCreate = false

    private func list(_ kind: CategoryKind) -> [SpendCategory] {
        categories.filter { $0.kind == kind }
    }

    var body: some View {
        List {
            section("Gider", items: list(.expense))
            section("Gelir", items: list(.income))
            if !list(.both).isEmpty {
                section("Karma", items: list(.both))
            }
        }
        .tabBarContentInset()
        .navigationTitle("Kategoriler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showCreate) { CategoryEditor(category: nil) }
        .sheet(item: $editing) { category in CategoryEditor(category: category) }
    }

    @ViewBuilder
    private func section(_ title: String, items: [SpendCategory]) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { category in
                    Button {
                        editing = category
                    } label: {
                        HStack(spacing: 12) {
                            CategoryBadge(symbol: category.symbol, color: category.color, size: 34)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(category.name)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text("\(count(for: category)) işlem")
                                    .font(.system(size: 11.5, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(items[index])
                    }
                    Haptics.warning()
                }
                .onMove { source, destination in
                    var reordered = items
                    reordered.move(fromOffsets: source, toOffset: destination)
                    for (index, item) in reordered.enumerated() {
                        item.sortIndex = index
                    }
                }
            }
        }
    }

    private func count(for category: SpendCategory) -> Int {
        txns.filter { $0.category?.id == category.id }.count
    }
}
