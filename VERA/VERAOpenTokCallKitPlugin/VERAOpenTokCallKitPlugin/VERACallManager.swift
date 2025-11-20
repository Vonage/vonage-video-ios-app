//
//  Created by Vonage on 6/11/25.
//

import CallKit
import Foundation

public protocol CallControllerProtocol {
    func request(_ transaction: CXTransaction) async throws
}

extension CXCallController: CallControllerProtocol {}

open class VERACallManager {

    enum Call: String {
        case start = "startCall"
        case end = "endCall"
        case hold = "holdCall"
    }

    let callController: CallControllerProtocol

    public init(callController: CallControllerProtocol = CXCallController()) {
        self.callController = callController
    }

    // MARK: Actions

    open func startCall(handle: String, callID: UUID) async throws {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: callID, handle: handle)
        startCallAction.isVideo = true

        let transaction = CXTransaction()
        transaction.addAction(startCallAction)

        try await requestTransaction(transaction, action: Call.start.rawValue)
    }

    open func end(callID: UUID) async throws {
        let endCallAction = CXEndCallAction(call: callID)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)

        try await requestTransaction(transaction, action: Call.end.rawValue)
    }

    open func setHeld(callID: UUID, onHold: Bool) async throws {
        let setHeldCallAction = CXSetHeldCallAction(call: callID, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        try await requestTransaction(transaction, action: Call.hold.rawValue)
    }

    private func requestTransaction(_ transaction: CXTransaction, action: String = "") async throws {
        try await callController.request(transaction)
    }
}
