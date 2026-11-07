//
//  WatchSyncService.swift
//  Budgett
//
//  Bridges the phone and the watch. The phone's app-group container is not
//  visible to the watch, so every snapshot is pushed over WatchConnectivity
//  (latest-wins application context).
//

import Foundation
import SwiftData
import WatchConnectivity

@MainActor
final class WatchSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchSyncService()

    /// Injected by the app; used to write quick-entry transactions the watch sends.
    var container: ModelContainer?

    private var session: WCSession?
    private var pending: BudgettSnapshot?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        self.session = session
    }

    func push(_ snapshot: BudgettSnapshot) {
        pending = snapshot
        send()
    }

    private func send() {
        guard let session, session.activationState == .activated else { return }
        guard let snapshot = pending, let data = SharedStore.encode(snapshot) else { return }
        pending = nil
        do {
            try session.updateApplicationContext([WatchSync.snapshotKey: data])
        } catch {
            pending = snapshot
        }
    }

    // MARK: - WCSessionDelegate (arrives on a background queue)

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.send() }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handleAddTxn(message, replyHandler: replyHandler)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // MARK: - Quick entry

    private func handleAddTxn(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let data = message[WatchSync.addTxnKey] as? Data,
              let request = SharedStore.decodeTxn(data),
              let container else {
            replyHandler(["success": false])
            return
        }

        let context = container.mainContext
        let txn = Txn(amount: request.amount,
                      kind: request.isIncome ? .income : .expense,
                      date: request.date)
        context.insert(txn)
        try? context.save()

        WidgetPublisher.publish(context: context, settings: AppSettings.shared)
        replyHandler(["success": true])
    }
}
