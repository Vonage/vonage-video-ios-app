//
//  Created by Vonage on 23/02/2026.
//

import Combine
import VERADomain

/// Null observer that never emits, used for previews and tests.
public final class NullCaptionsObserver: CaptionsObserver, Sendable {
    public var captionsReceived: AnyPublisher<[CaptionItem], Never> {
        Empty().eraseToAnyPublisher()
    }
}
