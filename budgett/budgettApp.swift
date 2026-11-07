//
//  budgettApp.swift
//  Budgett — akıllı harcama takibi
//

import SwiftUI
import SwiftData

@main
struct budgettApp: App {
    @State private var settings = AppSettings.shared
    @State private var router = AppRouter()
    @State private var gate = BiometricGate()
    @State private var showSplash = true

    private let container: ModelContainer

    init() {
        container = DataStore.makeContainer(cloud: AppSettings.shared.iCloudSync)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(\.settings, settings)
                    .environment(router)
                    .environment(gate)

                if showSplash {
                    SplashScreen()
                        .transition(.opacity.animation(.easeOut(duration: 0.2)))
                        .zIndex(1)
                }
            }
            .tint(settings.accent.color)
            .preferredColorScheme(settings.appearance.colorScheme)
            .fontDesign(.rounded)
            .task {
                // Let the splash animation complete before dismissing.
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
                WatchSyncService.shared.container = container
                WatchSyncService.shared.activate()
            }
        }
        .modelContainer(container)
    }
}
