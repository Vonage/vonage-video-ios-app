//
//  Created by Vonage on 8/2/26.
//

import Combine
import Foundation
import VERADomain

public final class DefaultCaptionsStatusDataSource: CaptionsStatusDataSource {
    private let _captionsState = CurrentValueRelay<CaptionsState, Never>(.disabled)
    public var captionsState: AnyPublisher<CaptionsState, Never> {
        _captionsState.publisher
    }

    public init() {
    }

    public func set(captionsState: CaptionsState) {
        _captionsState.send(captionsState)
    }

    public func reset() {
        _captionsState.send(.disabled)
    }
}
