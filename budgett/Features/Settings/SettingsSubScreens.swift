//
//  SettingsSubScreens.swift
//  Budgett
//

import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Appearance

struct AppearanceScreen: View {
    @Environment(\.settings) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Tema") {
                Picker("Tema", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                Picker("Gösterim", selection: $settings.currencyPresentation) {
                    ForEach(CurrencyPresentation.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                LabeledContent("Önizleme") {
                    AmountLabel(amount: Decimal(string: "1234.5")!, sign: .always, size: 18)
                }
            } header: {
                Text("Para gösterimi")
            }
        }
        .tabBarContentInset()
        .navigationTitle("Görünüm")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Currency

struct CurrencyScreen: View {
    @Environment(\.settings) private var settings
    @State private var search = ""

    private let popular = ["TRY", "USD", "EUR", "GBP", "CHF", "JPY", "AUD", "CAD", "SEK", "NOK", "DKK",
                           "RUB", "AED", "SAR", "QAR", "CNY", "INR", "KRW", "SGD", "HKD", "PLN", "CZK",
                           "HUF", "RON", "BGN", "UAH", "AZN", "GEL", "BRL", "MXN", "ARS", "ZAR", "NZD"]

    private var codes: [String] {
        let all = popular + Locale.commonISOCurrencyCodes.filter { !popular.contains($0) }
        guard !search.isEmpty else { return all }
        return all.filter {
            $0.localizedCaseInsensitiveContains(search)
                || Money.name(for: $0).localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            ForEach(codes, id: \.self) { code in
                Button {
                    settings.currencyCode = code
                    Haptics.selection()
                } label: {
                    HStack(spacing: 12) {
                        Text(Money.symbol(for: code))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .frame(width: 42, height: 32)
                            .background(Color.primary.opacity(0.06),
                                        in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(code)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Text(Money.name(for: code))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if settings.currencyCode == code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(settings.accent.color)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .tabBarContentInset()
        .searchable(text: $search, prompt: "Para birimi ara")
        .navigationTitle("Para birimi")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notifications

struct NotificationsScreen: View {
    @Environment(\.settings) private var settings
    @Query private var recurrences: [Recurrence]
    @State private var reminderTime = Date.now

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Günlük hatırlatma", isOn: $settings.dailyReminder)
                    .tint(Palette.controlTint)
                if settings.dailyReminder {
                    DatePicker("Saat", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .tint(Palette.controlTint)
                }
            } footer: {
                Text("Gün sonunda harcamalarını girmeyi unutma diye kısa bir dokunuş.")
            }

            Section {
                Toggle("Bütçe uyarıları", isOn: $settings.budgetAlerts)
                    .tint(Palette.controlTint)
            } footer: {
                Text("Bir bütçenin eşiğini geçtiğinde anında haber verir.")
            }

            Section {
                Toggle("Ödeme hatırlatmaları", isOn: $settings.billAlerts)
                    .tint(Palette.controlTint)
            } footer: {
                Text("Tekrar eden ödemelerden bir gün önce hatırlatır.")
            }
        }
        .tabBarContentInset()
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            var comps = DateComponents()
            comps.hour = settings.reminderHour
            comps.minute = settings.reminderMinute
            reminderTime = Calendar.current.date(from: comps) ?? .now
        }
        .onChange(of: reminderTime) { _, newValue in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            settings.reminderHour = comps.hour ?? 21
            settings.reminderMinute = comps.minute ?? 0
            Task { await Notifier.syncDailyReminder(settings: settings) }
        }
        .onChange(of: settings.dailyReminder) { _, _ in
            Task { await Notifier.syncDailyReminder(settings: settings) }
        }
        .onChange(of: settings.billAlerts) { _, _ in
            Task {
                await Notifier.syncBillReminders(
                    RecurringEngine.upcoming(recurrences, cal: settings.calendar), settings: settings)
            }
        }
        .onChange(of: settings.budgetAlerts) { _, isOn in
            if isOn { Task { _ = await Notifier.requestAuthorization() } }
        }
    }
}

// MARK: - Data

struct DataScreen: View {
    @Environment(\.settings) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Txn.date, order: .reverse) private var txns: [Txn]

    @State private var shareURL: URL?
    @State private var refreshToken = 0
    @State private var confirmErase = false
    @State private var confirmEraseAll = false
    @State private var showDemoConfirm = false

    private var widgetLinked: Bool { SharedStore.containerURL != nil }

    private var lastPublished: Date? {
        _ = refreshToken
        return SharedStore.load()?.updatedAt
    }

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Button {
                    shareURL = Exporter.exportCSV(txns, settings: settings)
                    Haptics.tap()
                } label: {
                    Label("CSV olarak dışa aktar", systemImage: "tablecells")
                }
                Button {
                    shareURL = Exporter.exportJSON(txns)
                    Haptics.tap()
                } label: {
                    Label("JSON yedeği al", systemImage: "doc.badge.arrow.up")
                }
            } header: {
                Text("Dışa aktar")
            } footer: {
                Text("\(txns.count) işlem dışa aktarılacak.")
            }

            Section {
                Toggle("iCloud senkronizasyonu", isOn: $settings.iCloudSync)
                    .tint(Palette.controlTint)
            } footer: {
                Text("Değişiklik uygulamayı yeniden başlattığında geçerli olur. Xcode ▸ Signing & Capabilities ▸ iCloud altında bir CloudKit container seçili olmalı; değilse uygulama sessizce yerel depoda kalır.")
            }

            Section {
                LabeledContent("App Group") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(widgetLinked ? Palette.income : Palette.warning)
                            .frame(width: 8, height: 8)
                        Text(widgetLinked ? "Bağlı" : "Kurulu değil")
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Kimlik", value: SharedStore.appGroupID)
                    .font(.system(size: 13, design: .monospaced))
                if let updated = lastPublished {
                    LabeledContent("Son güncelleme",
                                   value: updated.formatted(date: .abbreviated, time: .shortened))
                }
                Button {
                    WidgetPublisher.publish(context: context, settings: settings)
                    WidgetCenter.shared.reloadAllTimelines()
                    refreshToken += 1
                    Haptics.success()
                } label: {
                    Label("Widget verisini şimdi yenile", systemImage: "arrow.clockwise")
                }
                .disabled(!widgetLinked)
            } header: {
                Text("Widget")
            } footer: {
                Text(widgetLinked
                     ? "Widget'lar bu App Group içindeki özet dosyasını okuyor. Veri her değişiklikte otomatik yazılır."
                     : "Widget'ların veri görebilmesi için Xcode ▸ Signing & Capabilities altında hem budgett hem BudgettWidgetsExtension hedefine App Groups ekleyip \(SharedStore.appGroupID) grubunu işaretle.")
            }

            Section {
                Button {
                    showDemoConfirm = true
                } label: {
                    Label("Örnek veri yükle", systemImage: "wand.and.sparkles")
                }
            } footer: {
                Text("Grafikleri denemek için iki aylık gerçekçi hareket üretir.")
            }

            Section {
                Button(role: .destructive) {
                    confirmErase = true
                } label: {
                    Label("Tüm işlemleri sil", systemImage: "trash")
                }
                Button(role: .destructive) {
                    confirmEraseAll = true
                } label: {
                    Label("Her şeyi sıfırla", systemImage: "exclamationmark.triangle")
                }
            } header: {
                Text("Tehlikeli bölge")
            }
        }
        .tabBarContentInset()
        .navigationTitle("Veri")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareURL) { url in
            ShareLinkSheet(url: url)
        }
        .confirmationDialog("Tüm işlemler silinsin mi?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Sil", role: .destructive) {
                DataStore.eraseTransactions(context)
                Haptics.warning()
            }
        } message: {
            Text("Kategoriler, bütçeler ve cüzdanlar korunur.")
        }
        .confirmationDialog("Her şey silinsin mi?", isPresented: $confirmEraseAll, titleVisibility: .visible) {
            Button("Her şeyi sil", role: .destructive) {
                DataStore.eraseAll(context)
                settings.resetPreferences()
                DataStore.bootstrap(context)
                Haptics.warning()
            }
        } message: {
            Text("İşlemler, bütçeler, hedefler, cüzdanlar ve kategoriler sıfırlanır.")
        }
        .confirmationDialog("Örnek veri eklensin mi?", isPresented: $showDemoConfirm, titleVisibility: .visible) {
            Button("Ekle") {
                DataStore.loadDemoData(context)
                Haptics.success()
            }
        } message: {
            Text("Mevcut kayıtların korunur, üzerine örnek hareketler eklenir.")
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
