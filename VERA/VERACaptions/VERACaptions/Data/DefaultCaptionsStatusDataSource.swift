//
//  Created by Vonage on 8/2/26.
//

import Combine
import Foundation
import VERADomain

public final class DefaultCaptionsStatusDataSource: CaptionsStatusDataSource {
    private var _captionsState = CurrentValueSubject<CaptionsState, Never>(.disabled)
    public lazy var captionsState: AnyPublisher<CaptionsState, Never> = _captionsState.eraseToAnyPublisher()

    public init() {
    }

    public func set(captionsState: CaptionsState) {
        _captionsState.value = captionsState
    }

    public func reset() {
        _captionsState.value = .disabled
    }
}
