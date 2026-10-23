//
//  Created by Vonage on 16/10/26.
//

import Foundation
import os

/// Tracks the microphone mute state CallKit knows about, so app-side mute changes
/// are reported to CallKit exactly once and CallKit's echo of those reports is not
/// applied back to the call.
///
/// CallKit answers every `CXSetMutedCallAction` the app requests by calling
/// `provider(_:perform:)` with the same action. Without filtering, a fast
/// mute → unmute in the app would be replayed onto the call by the delayed echo.
///
/// Thread-safe: the state is guarded by a lock because it is touched from the
/// media state publisher, the CallKit provider queue and request completions.
final class CallKitMuteSynchronizer: Sendable {

    private struct State {
        /// The mute state CallKit holds (or will hold once pending requests land).
        var callKitIsMuted = false
        /// Mute values requested by the app whose CallKit echo has not arrived yet, in request order.
        var pendingEchoes: [Bool] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    /// Restores the state of a newly started CallKit call, which always begins unmuted.
    func reset() {
        state.withLock { $0 = State() }
    }

    /// Records an app-side mute state and tells whether CallKit has to be updated.
    ///
    /// - Parameter isMuted: The app's current microphone mute state.
    /// - Returns: `true` when CallKit holds a different value and a request must be sent.
    func shouldReport(isMuted: Bool) -> Bool {
        state.withLock { state in
            guard state.callKitIsMuted != isMuted else { return false }
            state.callKitIsMuted = isMuted
            state.pendingEchoes.append(isMuted)
            return true
        }
    }

    /// Rolls back a report that CallKit rejected, so it never echoes it.
    ///
    /// - Parameter isMuted: The value that was requested.
    func reportFailed(isMuted: Bool) {
        state.withLock { state in
            if let index = state.pendingEchoes.firstIndex(of: isMuted) {
                state.pendingEchoes.remove(at: index)
            }
            state.callKitIsMuted = !isMuted
        }
    }

    /// Handles a mute action performed by CallKit.
    ///
    /// - Parameter isMuted: The mute value CallKit performed.
    /// - Returns: `true` when the action is the echo of an app-side report and must not
    ///   be applied to the call; `false` when it came from the system UI.
    func consumeEcho(isMuted: Bool) -> Bool {
        state.withLock { state in
            if state.pendingEchoes.first == isMuted {
                state.pendingEchoes.removeFirst()
                return true
            }
            state.callKitIsMuted = isMuted
            return false
        }
    }
}
