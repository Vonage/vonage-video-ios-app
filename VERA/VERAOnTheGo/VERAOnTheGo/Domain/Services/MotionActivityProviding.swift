//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Source of motion-activity samples (e.g. CoreMotion on iOS).
///
/// Implementations must deliver `handler` on the main actor. Starting and
/// stopping never triggers a permission prompt by itself; querying
/// `authorizationStatus` does not either.
@MainActor
public protocol MotionActivityProviding: AnyObject {
    /// Whether motion activity data can be produced on this device at all.
    var isAvailable: Bool { get }

    /// Current authorization status for motion & fitness access.
    var authorizationStatus: MotionAuthorizationStatus { get }

    /// Starts delivering samples to `handler` on the main actor.
    func start(_ handler: @escaping @MainActor (MotionSample) -> Void)

    /// Stops delivering samples.
    func stop()
}
