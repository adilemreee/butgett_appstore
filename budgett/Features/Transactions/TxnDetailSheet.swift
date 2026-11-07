//
//  TxnDetailSheet.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct TxnDetailSheet: View {
    var txn: Txn

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings
    @Environment(AppRouter.self) private var router
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    VStack(spacing: 0) {
                        detailRow("Kategori", value: txn.category?.name ?? "Kategorisiz",
                                  symbol: txn.glyph, tint: txn.accentColor)
                        if let wallet = txn.wallet {
                            Divider().padding(.leading, 52)
                            detailRow("Cüzdan", value: wallet.name, symbol: wallet.symbol, tint: wallet.color)
                        }
                        Divider().padding(.leading, 52)
                        detailRow("Tarih", value: txn.date.formatted(date: .complete, time: .shortened),
                                  symbol: "calendar", tint: .secondary)
                        if txn.recurrenceID != nil {
                            Divider().padding(.leading, 52)
                            detailRow("Kaynak", value: "Otomatik tekrar",
                                      symbol: "arrow.trianglehead.2.clockwise.rotate.90", tint: Palette.transfer)
                        }
                        if txn.isExcluded {
                            Divider().padding(.leading, 52)
                            detailRow("Durum", value: "Analiz dışı", symbol: "eye.slash", tint: Palette.warning)
                        }
                    }
                    .padding(.vertical, 4)
                    .softCard()

                    if !txn.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(txn.tags, id: \.self) { tag in
                                TagChip(text: "#\(tag)", color: settings.accent.color)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !txn.note.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHeader(title: "Not")
                            Text(txn.note)
                                .font(.system(size: 15, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .softCard()
                    }

                    if let data = txn.receipt, let image = UIImage(data: data) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Fiş")
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }

                    actions
                }
                .padding(Metrics.hPadding)
                .padding(.bottom, 24)
            }
            .background(AuroraBackground(accent: settings.accent))
            .navigationTitle("İşlem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Düzenle") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            router.edit(txn)
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Bu işlem silinsin mi?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Sil", role: .destructive) {
                    context.delete(txn)
                    Haptics.warning()
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            CategoryBadge(symbol: txn.glyph, color: txn.accentColor, size: 62)
            Text(txn.displayTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            AmountLabel(amount: txn.kind == .expense ? -txn.amount : txn.amount,
                        sign: .always, size: 40,
                        tint: txn.kind == .income ? Palette.income : .primary)
            Text(txn.kind.title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(txn.kind.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(txn.kind.color.opacity(0.14), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .glassCard(radius: 30)
    }

    private func detailRow(_ title: String, value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                let copy = Txn(amount: txn.amount, kind: txn.kind, date: .now,
                               title: txn.title, note: txn.note,
                               category: txn.category, wallet: txn.wallet,
                               tags: txn.tags, currencyCode: txn.currencyCode)
                context.insert(copy)
                Haptics.success()
                dismiss()
            } label: {
                Label("Kopyala", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)

            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Sil", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(Palette.expense)
        }
    }
}
