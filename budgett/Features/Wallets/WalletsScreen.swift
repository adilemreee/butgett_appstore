//
//  WalletsScreen.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct WalletsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings
    @Query(sort: \Wallet.sortIndex) private var wallets: [Wallet]
    @Query private var txns: [Txn]

    @State private var editing: Wallet?
    @State private var showCreate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Toplam varlık")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        AmountLabel(amount: NetWorth.total(wallets: wallets, txns: txns), size: 26)
                    }
                    Spacer()
                }
                .padding(16)
                .glassCard()

                ForEach(wallets) { wallet in
                    Button {
                        editing = wallet
                    } label: {
                        walletRow(wallet)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Düzenle", systemImage: "pencil") { editing = wallet }
                        Button("Sil", systemImage: "trash", role: .destructive) {
                            context.delete(wallet)
                        }
                    }
                }

                Button {
                    showCreate = true
                } label: {
                    Label("Cüzdan ekle", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
            }
            .padding(Metrics.hPadding)
            .padding(.bottom, Metrics.tabBarClearance)
        }
        .background(AuroraBackground(accent: settings.accent))
        .navigationTitle("Cüzdanlar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreate) { WalletEditor(wallet: nil) }
        .sheet(item: $editing) { wallet in WalletEditor(wallet: wallet) }
    }

    private func walletRow(_ wallet: Wallet) -> some View {
        HStack(spacing: 12) {
            CategoryBadge(symbol: wallet.symbol, color: wallet.color, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(wallet.name)
                    .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                Text("\(wallet.type.title) · \(wallet.movementCount(in: txns)) hareket")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            AmountLabel(amount: wallet.balance(from: txns), size: 17,
                        tint: wallet.balance(from: txns) < 0 ? Palette.expense : .primary)
        }
        .padding(14)
        .glassCard(radius: 22)
    }
}

struct WalletEditor: View {
    var wallet: Wallet?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.settings) private var settings
    @Query private var wallets: [Wallet]

    @State private var name = ""
    @State private var balanceText = ""
    @State private var type: WalletType = .cash
    @State private var colorHex = "3B5BFF"
    @State private var symbol = "wallet.bifold.fill"
    @State private var includeInNetWorth = true

    private var tint: Color { Color(hex: colorHex) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(tint)
                            .frame(width: 34, height: 34)
                            .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        TextField("Cüzdan adı", text: $name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    Picker("Tür", selection: $type) {
                        ForEach(WalletType.allCases) { Label($0.title, systemImage: $0.symbol).tag($0) }
                    }
                    HStack {
                        Text("Açılış bakiyesi")
                        Spacer()
                        Text(settings.currencySymbol).foregroundStyle(.secondary)
                        TextField("0", text: $balanceText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 140)
                    }
                    Toggle("Toplam varlığa dahil et", isOn: $includeInNetWorth)
                        .tint(Palette.controlTint)
                }

                Section("Simge") {
                    SymbolGrid(symbols: Palette.walletSymbols, selection: $symbol, tint: .primary)
                }

                if let wallet {
                    Section {
                        Button("Cüzdanı sil", role: .destructive) {
                            context.delete(wallet)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(wallet == nil ? "Yeni cüzdan" : "Cüzdanı düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
            .onChange(of: type) { _, newValue in
                if wallet == nil { symbol = newValue.symbol }
            }
        }
    }

    private func load() {
        guard let wallet else { return }
        name = wallet.name
        balanceText = Money.number(wallet.openingBalance)
        type = wallet.type
        colorHex = wallet.colorHex
        symbol = wallet.symbol
        includeInNetWorth = wallet.includeInNetWorth
    }

    private func save() {
        let target: Wallet
        if let wallet {
            target = wallet
        } else {
            target = Wallet(name: name, sortIndex: (wallets.map(\.sortIndex).max() ?? 0) + 1)
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.openingBalance = Money.decimal(from: balanceText)
        target.type = type
        target.colorHex = colorHex
        target.symbol = symbol
        target.includeInNetWorth = includeInNetWorth
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
