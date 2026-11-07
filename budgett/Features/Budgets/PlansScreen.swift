//
//  PlansScreen.swift
//  Budgett
//
//  Budgets, savings goals and recurring bills live under one tab.
//

import SwiftUI
import SwiftData

enum PlanSection: String, CaseIterable, Identifiable {
    case budgets, goals, recurring
    var id: String { rawValue }
    var title: String {
        switch self {
        case .budgets: "Bütçeler"
        case .goals: "Hedefler"
        case .recurring: "Abonelikler"
        }
    }
}

struct PlansScreen: View {
    @Environment(\.settings) private var settings
    @State private var section: PlanSection = .budgets
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GlassSegmented(options: PlanSection.allCases,
                                   title: { $0.title },
                                   selection: $section)
                        .padding(.horizontal, Metrics.hPadding)

                    switch section {
                    case .budgets: BudgetsSection(showCreate: $showCreate)
                    case .goals: GoalsSection(showCreate: $showCreate)
                    case .recurring: RecurringSection(showCreate: $showCreate)
                    }

                    Color.clear.frame(height: Metrics.tabBarClearance)
                }
                .padding(.top, 6)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Planlar")
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreate = true
                        Haptics.tap()
                    } label: {
                        Label("Yeni", systemImage: "plus")
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
