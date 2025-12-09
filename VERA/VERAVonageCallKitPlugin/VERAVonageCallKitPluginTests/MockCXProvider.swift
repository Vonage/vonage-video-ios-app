//
//  Created by Vonage on 20/11/25.
//

import CallKit
import Foundation

@testable import VERAVonageCallKitPlugin

final class MockCXProvider: CXProviderProtocol {
    enum Action: Equatable {
        case setDelegate
        case reportCall(UUID, CXCallUpdate)
        case reportCallConnectedAt(UUID, Date?)
        case reportCallStartedConnectingAt(UUID, Date?)
    }

    var recordedActions: [Action] = []
    weak var delegate: CXProviderDelegate?

    func setDelegate(_ delegate: CXProviderDelegate?, queue: DispatchQueue?) {
        recordedActions.append(.setDelegate)
        self.delegate = delegate
    }

    func reportCall(with UUID: UUID, updated update: CXCallUpdate) {
        recordedActions.append(.reportCall(UUID, update))
    }

    func reportOutgoingCall(with UUID: UUID, connectedAt: Date?) {
        recordedActions.append(.reportCallConnectedAt(UUID, connectedAt))
    }

    func reportOutgoingCall(with UUID: UUID, startedConnectingAt: Date?) {
        recordedActions.append(.reportCallStartedConnectingAt(UUID, startedConnectingAt))
    }
}
