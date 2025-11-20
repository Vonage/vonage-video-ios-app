//
//  Created by Vonage on 20/11/25.
//

import CallKit
import Foundation

@testable import VERAOpenTokCallKitPlugin

final class MockCXProvider: CXProviderProtocol {
    enum Action: Equatable {
        case setDelegate
        case reportCall(UUID, CXCallUpdate)
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
}
