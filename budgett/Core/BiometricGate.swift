//
//  BiometricGate.swift
//  Budgett
//

import LocalAuthentication
import Observation

@Observable
final class BiometricGate {
    var isUnlocked: Bool = false
    var lastError: String?

    var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Parola"
        }
    }

    func lock() { isUnlocked = false }

    func authenticate() async {
        let context = LAContext()
        context.localizedCancelTitle = "İptal"
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Bütçeni açmak için kimliğini doğrula"
            )
            isUnlocked = ok
            lastError = nil
        } catch {
            isUnlocked = false
            lastError = error.localizedDescription
        }
    }
}
