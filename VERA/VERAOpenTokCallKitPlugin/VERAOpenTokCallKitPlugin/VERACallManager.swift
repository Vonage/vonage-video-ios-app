//
//  VERACallManager.swift
//  VERAOpenTokCallKitPlugin
//
//  Created by Ivan Ornes on 6/11/25.
//

import CallKit
import Foundation

final class VERACallManager {

    enum Call: String {
        case start = "startCall"
        case end = "endCall"
        case hold = "holdCall"
    }

    let callController = CXCallController()

    // MARK: Actions

    func startCall(handle: String, callID: UUID) {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: callID, handle: handle)

        startCallAction.isVideo = true

        let transaction = CXTransaction()
        transaction.addAction(startCallAction)

        requestTransaction(transaction, action: Call.start.rawValue)
    }

    func end(callID: UUID) {
        let endCallAction = CXEndCallAction(call: callID)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)

        requestTransaction(transaction, action: Call.end.rawValue)
    }

    func setHeld(callID: UUID, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: callID, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        requestTransaction(transaction, action: Call.hold.rawValue)
    }

    private func requestTransaction(_ transaction: CXTransaction, action: String = "") {
        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting transaction: \(error)")
            } else {
                print("Requested transaction \(action) successfully")
            }
        }
    }
}
