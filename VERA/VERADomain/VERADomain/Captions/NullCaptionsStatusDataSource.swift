//
//  Created by Vonage on 11/2/26.
//

import Combine
import Foundation

public final class NullCaptionsStatusDataSource: CaptionsStatusDataSource {
    public var captionsState: AnyPublisher<CaptionsState, Never> = CurrentValueSubject(.disabled).eraseToAnyPublisher()

    public init() {
    }

    public func set(captionsState: CaptionsState) {
    }

    public func reset() {
    }
}
