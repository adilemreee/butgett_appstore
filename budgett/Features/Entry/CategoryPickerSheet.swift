//
//  CategoryPickerSheet.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct CategoryPickerSheet: View {
    @Binding var selection: SpendCategory?
    var kind: TxnKind

    @Environment(\.dismiss) private var dismiss
    @Environment(\.settings) private var settings
    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]
    @State private var search = ""
    @State private var showEditor = false

    private var filtered: [SpendCategory] {
        categories
            .filter { !$0.isArchived && $0.kind.matches(kind) }
            .filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(filtered) { category in
                        Button {
                            selection = category
                            Haptics.selection()
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                CategoryBadge(symbol: category.symbol, color: category.color, size: 52)
                                    .overlay {
                                        if selection?.id == category.id {
                                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                                .strokeBorder(Color.primary, lineWidth: 2.5)
                                                .padding(-4)
                                        }
                                    }
                                Text(category.name)
                                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        .buttonStyle(.pressable)
                    }

                    Button {
                        showEditor = true
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                .foregroundStyle(.tertiary)
                                .frame(width: 52, height: 52)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            Text("Yeni")
                                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.pressable)
                }
                .padding(Metrics.hPadding)
            }
            .background(AuroraBackground(accent: settings.accent))
            .searchable(text: $search, prompt: "Kategori ara")
            .navigationTitle("Kategori seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                if selection != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Temizle") { selection = nil; dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                CategoryEditor(category: nil, defaultKind: kind == .income ? .income : .expense) { created in
                    selection = created
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
