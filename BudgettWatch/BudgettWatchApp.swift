//
//  BudgettWatchApp.swift
//  BudgettWatch
//
//  Watch companion for Budgett. It never touches the SwiftData store; it reads
//  the same shared snapshot the widgets use, so it stays lean and always shows
//  the same numbers as the phone.
//

import SwiftUI

@main
struct BudgettWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .fontDesign(.rounded)
        }
    }
}
