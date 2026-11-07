//
//  RootView.swift
//  Budgett
//

import SwiftUI
import SwiftData
import WidgetKit

struct RootView: View {
    @Environment(\.settings) private var settings
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @Environment(BiometricGate.self) private var gate
    @Environment(\.scenePhase) private var scenePhase

    @Query private var recurrences: [Recurrence]
    @Query private var txns: [Txn]
    @Query private var budgets: [BudgetPlan]

    @State private var didBootstrap = false

    /// Cheap signature of everything the widgets care about.
    private var widgetFingerprint: Int {
        var hasher = Hasher()
        hasher.combine(txns.count)
        hasher.combine(txns.map(\.updatedAt).max())
        hasher.combine(budgets.count)
        hasher.combine(recurrences.count)
        hasher.combine(settings.currencyCode)
        hasher.combine(settings.showCents)
        hasher.combine(settings.privacyMode)
        hasher.combine(settings.accent)
        return hasher.finalize()
    }

    var body: some View {
        @Bindable var router = router

        ZStack(alignment: .bottom) {
            AuroraBackground()

            TabView(selection: $router.tab) {
                FlowScreen()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(AppTab.flow)
                InsightsScreen()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(AppTab.insights)
                PlansScreen()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(AppTab.plans)
                SettingsScreen()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(AppTab.settings)
            }
            .ignoresSafeArea(.keyboard)

            FloatingTabBar(selection: $router.tab, onAdd: { router.newTransaction() })
        }
        .sheet(isPresented: $router.showQuickEntry) {
            QuickEntryScreen(existing: router.editingTxn, initialKind: router.quickEntryKind)
        }
        .overlay {
            if settings.biometricLock && !gate.isUnlocked {
                LockScreen()
                    .transition(.opacity)
            }
        }
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            DataStore.bootstrap(context)
            RecurringEngine.postDue(context: context, cal: settings.calendar)
            if settings.biometricLock { await gate.authenticate() }
            await Notifier.syncDailyReminder(settings: settings)
            WidgetPublisher.publish(context: context, settings: settings)
        }
        .onChange(of: widgetFingerprint) { _, _ in
            WidgetPublisher.publish(context: context, settings: settings)
        }
        .onOpenURL { url in open(url) }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                RecurringEngine.postDue(context: context, cal: settings.calendar)
                consumePendingEntry()
            case .background:
                if settings.biometricLock { gate.lock() }
                WidgetPublisher.publish(context: context, settings: settings)
            default: break
            }
        }
        .onChange(of: recurrences.count) { _, _ in
            Task {
                await Notifier.syncBillReminders(
                    RecurringEngine.upcoming(recurrences, cal: settings.calendar),
                    settings: settings)
            }
        }
    }

    // MARK: - Deep links

    /// budgett://new?kind=expense · budgett://open?tab=insights
    private func open(_ url: URL) {
        guard url.scheme == BudgettLink.scheme else { return }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch url.host {
        case "new":
            let raw = query.first { $0.name == "kind" }?.value ?? "expense"
            router.newTransaction(kind: TxnKind(rawValue: raw) ?? .expense)
        case "open":
            let name = query.first { $0.name == "tab" }?.value ?? "flow"
            switch name {
            case "insights": router.tab = .insights
            case "plans": router.tab = .plans
            case "settings": router.tab = .settings
            default: router.tab = .flow
            }
        default:
            break
        }
    }

    /// The Control Center button and lock screen widgets drop a flag instead of
    /// a URL, because controls launch the app without one.
    private func consumePendingEntry() {
        let defaults = SharedStore.defaults
        let standard = UserDefaults.standard
        let pending = defaults.bool(forKey: SharedStore.pendingEntryKey)
            || standard.bool(forKey: SharedStore.pendingEntryKey)
        guard pending else { return }
        defaults.set(false, forKey: SharedStore.pendingEntryKey)
        standard.set(false, forKey: SharedStore.pendingEntryKey)
        router.newTransaction()
    }
}

// MARK: - Lock screen

struct LockScreen: View {
    @Environment(BiometricGate.self) private var gate
    @Environment(\.settings) private var settings

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            VStack(spacing: 22) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(settings.accent.color)
                    .symbolEffect(.bounce, value: gate.isUnlocked)
                VStack(spacing: 6) {
                    Text("Budgett kilitli")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("Devam etmek için \(gate.biometryName) kullan.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await gate.authenticate() }
                } label: {
                    Label("Kilidi Aç", systemImage: "faceid")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.inkProminent)
                .controlSize(.large)
            }
            .padding(32)
        }
    }
}
