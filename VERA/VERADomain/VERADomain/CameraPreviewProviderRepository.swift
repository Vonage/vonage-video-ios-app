//
//  Created by Vonage on 8/8/25.
//

import Combine
import Foundation

/// CameraPreviewProviderRepository manages publisher instances across different app contexts.
///
/// We use this repository pattern for several key reasons:
///
/// a) Video scaling behavior requirements differ between contexts:
///    - Preview (waiting room): Uses .fit scaling to show full camera view without cropping
///    - Meeting room: Uses .fill scaling to optimize screen real estate since we control sizing manually
///
/// b) Publisher username immutability:
///    - The username is a constant set during publisher initialization
///    - Waiting room: Username parameter is irrelevant for preview functionality
///    - Meeting room: Username is critical for participant identification and display
///    - We cannot reuse the same publisher instance when transitioning between contexts
///
/// c) Memory management and bug prevention:
///    - Provides clean separation between preview and meeting publisher lifecycles
///    - Reduces username-related bugs by ensuring fresh publisher instances
///    - Facilitates proper cleanup and resource management between app states
public protocol CameraPreviewProviderRepository {
    func getPublisher() throws -> VERAPublisher
    func resetPublisher()

    /// Emits when ``resetPublisher()`` is called so subscribers (e.g. the
    /// waiting-room view model) can re-fetch a fresh publisher built with
    /// the latest advanced settings (resolution, frame rate, codec, etc.).
    var didResetPublisher: AnyPublisher<Void, Never> { get }
}
