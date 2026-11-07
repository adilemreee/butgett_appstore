//
//  SettingsScreen.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Environment(\.settings) private var settings
    @Environment(BiometricGate.self) private var gate

    @Query private var txns: [Txn]
    @Query private var wallets: [Wallet]
    @Query private var categories: [SpendCategory]

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    summaryCard
                        .padding(.horizontal, Metrics.hPadding)

                    group("Genel") {
                        NavigationLink {
                            AppearanceScreen()
                        } label: {
                            settingsRow("Görünüm", value: settings.appearance.title,
                                        symbol: settings.appearance.symbol, chevron: true)
                        }
                        divider
                        NavigationLink {
                            CurrencyScreen()
                        } label: {
                            settingsRow("Para birimi", value: settings.currencyCode,
                                        symbol: "turkishlirasign.circle", chevron: true)
                        }
                        divider
                        Menu {
                            Picker("Haftanın ilk günü", selection: $settings.firstWeekday) {
                                ForEach(1...7, id: \.self) { day in
                                    Text(weekdayName(day)).tag(day)
                                }
                            }
                        } label: {
                            settingsRow("Haftanın ilk günü", value: weekdayName(settings.firstWeekday),
                                        symbol: "calendar", chevron: true)
                        }
                        divider
                        Menu {
                            Picker("Tuş takımı", selection: $settings.keypadStyle) {
                                ForEach(KeypadStyle.allCases) { Text($0.title).tag($0) }
                            }
                        } label: {
                            settingsRow("Tuş takımı", value: settings.keypadStyle.title,
                                        symbol: "square.grid.3x3", chevron: true)
                        }
                        divider
                        Menu {
                            Picker("Varsayılan dönem", selection: $settings.defaultPeriod) {
                                ForEach(Period.allCases) { Text($0.title).tag($0) }
                            }
                        } label: {
                            settingsRow("Varsayılan dönem", value: settings.defaultPeriod.title,
                                        symbol: "clock", chevron: true)
                        }
                    }

                    group("Davranış") {
                        toggleRow("Gelir takibi", symbol: "arrow.up.right.circle", isOn: $settings.trackIncome)
                        divider
                        toggleRow("Kuruşları göster", symbol: "centsign.circle", isOn: $settings.showCents)
                        divider
                        toggleRow("Yaklaşan ödemeleri listele", symbol: "calendar.badge.clock", isOn: $settings.carryUpcoming)
                        divider
                        toggleRow("Titreşim", symbol: "iphone.radiowaves.left.and.right", isOn: $settings.hapticsEnabled)
                        divider
                        toggleRow("Gizli mod", symbol: "eye.slash", isOn: $settings.privacyMode)
                        if gate.isAvailable {
                            divider
                            toggleRow("\(gate.biometryName) kilidi", symbol: "faceid", isOn: $settings.biometricLock)
                        }
                    }

                    group("Veri") {
                        NavigationLink {
                            CategoriesScreen()
                        } label: {
                            settingsRow("Kategoriler", value: "\(categories.count)",
                                        symbol: "square.grid.2x2", chevron: true)
                        }
                        divider
                        NavigationLink {
                            WalletsScreen()
                        } label: {
                            settingsRow("Cüzdanlar", value: "\(wallets.count)",
                                        symbol: "wallet.bifold", chevron: true)
                        }
                        divider
                        NavigationLink {
                            NotificationsScreen()
                        } label: {
                            settingsRow("Bildirimler",
                                        value: settings.dailyReminder || settings.budgetAlerts || settings.billAlerts ? "Açık" : "Kapalı",
                                        symbol: "bell.badge", chevron: true)
                        }
                        divider
                        NavigationLink {
                            DataScreen()
                        } label: {
                            settingsRow("Dışa aktar & yedek", value: "\(txns.count) kayıt",
                                        symbol: "square.and.arrow.up", chevron: true)
                        }
                    }

                    aboutCard
                        .padding(.horizontal, Metrics.hPadding)

                    Color.clear.frame(height: Metrics.tabBarClearance)
                }
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Ayarlar")
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Pieces

    private var summaryCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "chart.pie")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.primary))
            VStack(alignment: .leading, spacing: 3) {
                Text("Budgett")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("\(txns.count) işlem · \(wallets.count) cüzdan")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text("VARLIK")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
                AmountLabel(amount: NetWorth.total(wallets: wallets, txns: txns), size: 16)
            }
        }
        .padding(16)
        .glassCard(radius: 26)
    }

    private var aboutCard: some View {
        VStack(spacing: 8) {
            Text("Budgett \(appVersion)")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text("Verilerin cihazında kalır. iCloud senkronizasyonunu açarsan yalnızca senin hesabında saklanır.")
                .font(.system(size: 11.5, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(version)"
    }

    private var divider: some View {
        Divider().padding(.leading, 46)
    }

    @ViewBuilder
    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title)
                .padding(.horizontal, 6)
            VStack(spacing: 0) { content() }
                .padding(.vertical, 4)
                .glassCard(radius: 22)
        }
        .padding(.horizontal, Metrics.hPadding)
    }

    private func settingsRow(_ title: String, value: String?, symbol: String,
                             chevron: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .center)
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.primary)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func toggleRow(_ title: String, symbol: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            settingsRow(title, value: nil, symbol: symbol)
        }
        .toggleStyle(.switch)
        .tint(Palette.controlTint)
        .padding(.trailing, 4)
    }

    private func weekdayName(_ index: Int) -> String {
        let symbols = Calendar.current.standaloneWeekdaySymbols
        return symbols[(index - 1) % 7].capitalized
    }
}
