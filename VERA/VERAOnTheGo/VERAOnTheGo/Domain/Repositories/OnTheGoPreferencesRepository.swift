//
//  Created by Vonage on 17/10/26.
//

import Combine
import Foundation

/// Stores the user's On-the-Go preferences.
public protocol OnTheGoPreferencesRepository: AnyObject {
    /// Whether the app may suggest On-the-Go mode when motion is detected.
    /// Defaults to `true`. Persisted under `onTheGo.suggestWhenMoving`.
    var suggestWhenMoving: Bool { get set }

    /// Emits the current value and every change. Implementations emit on the
    /// main thread.
    var suggestWhenMovingPublisher: AnyPublisher<Bool, Never> { get }
}
