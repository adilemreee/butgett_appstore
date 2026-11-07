//
//  WatchSyncStore.swift
//  BudgettWatch
//
//  Receives the snapshot from the iPhone over WatchConnectivity, keeps it in
//  the watch's Documents directory (no app-group requirement) and exposes it
//  to the UI. The phone always wins: it sends the latest snapshot, so the
//  watch never has to read the SwiftData store.
//

import Foundation
import WatchConnectivity
import Observation

@MainActor
@Observable
final class WatchSyncStore: NSObject, WCSessionDelegate {
    static let shared = WatchSyncStore()

    private(set) var snapshot: BudgettSnapshot?

    nonisolated static var localURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("watch-snapshot.json")
    }

    private override init() {
        super.init()
    }

    func activate() {
        loadFromDisk()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Fallback: whatever the phone delivered last time, still on disk.
    func loadFromDisk() {
        guard let url = Self.localURL,
              let data = try? Data(contentsOf: url),
              let snapshot = SharedStore.decode(data) else { return }
        self.snapshot = snapshot
    }

    /// Asks the phone to record a quick expense/income and replies with success.
    func addTransaction(amount: Decimal, isIncome: Bool, completion: @escaping (Bool) -> Void) {
        guard WCSession.isSupported() else {
            completion(false)
            return
        }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else {
            completion(false)
            return
        }

        let request = WatchTxnRequest(amount: amount, isIncome: isIncome, date: .now)
        guard let data = SharedStore.encodeTxn(request) else {
            completion(false)
            return
        }

        session.sendMessage([WatchSync.addTxnKey: data], replyHandler: { reply in
            let ok = (reply["success"] as? Bool) ?? false
            DispatchQueue.main.async { completion(ok) }
        }, errorHandler: { _ in
            DispatchQueue.main.async { completion(false) }
        })
    }

    // MARK: - WCSessionDelegate (arrives on a background queue)

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        apply(session.receivedApplicationContext)
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    nonisolated private func apply(_ payload: [String: Any]) {
        guard let data = payload[WatchSync.snapshotKey] as? Data else { return }

        if let url = Self.localURL {
            try? data.write(to: url, options: .atomic)
        }

        Task { @MainActor in
            self.ingest(data)
        }
    }

    private func ingest(_ data: Data) {
        guard let snapshot = SharedStore.decode(data) else { return }
        self.snapshot = snapshot
    }
}
