//
//  Created by Vonage on 20/11/25.
//

import CallKit
import Foundation

@testable import VERAVonageCallKitPlugin

final class MockCallController: CallControllerProtocol {

    enum Action: Equatable {
        case startCall(callID: UUID, handle: String, isVideo: Bool)
        case endCall(callID: UUID)
        case setHeld(callID: UUID, onHold: Bool)
    }

    var recordedActions: [Action] = []
    var errorToReturn: Error?
    var requestCallCount = 0

    func request(_ transaction: CXTransaction) async throws {
        requestCallCount += 1

        for action in transaction.actions {
            switch action {
            case let startAction as CXStartCallAction:
                recordedActions.append(
                    .startCall(
                        callID: startAction.callUUID,
                        handle: startAction.handle.value,
                        isVideo: startAction.isVideo
                    ))
            case let endAction as CXEndCallAction:
                recordedActions.append(.endCall(callID: endAction.callUUID))
            case let heldAction as CXSetHeldCallAction:
                recordedActions.append(.setHeld(callID: heldAction.callUUID, onHold: heldAction.isOnHold))
            default:
                break
            }
        }

        if let error = errorToReturn {
            throw error
        }
    }
}
