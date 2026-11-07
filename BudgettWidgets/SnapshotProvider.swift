//
//  SnapshotProvider.swift
//  BudgettWidgets
//

import WidgetKit
import SwiftUI

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: BudgettSnapshot
}

struct SnapshotProvider: TimelineProvider {

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : (SharedStore.load() ?? .placeholder)
        completion(SnapshotEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = SharedStore.load() ?? .placeholder
        let entry = SnapshotEntry(date: .now, snapshot: snapshot)
        // The app reloads timelines whenever data changes; this is just a safety net
        // so day boundaries and "days left" counters stay honest.
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now)
            ?? Date.now.addingTimeInterval(1_800)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}
