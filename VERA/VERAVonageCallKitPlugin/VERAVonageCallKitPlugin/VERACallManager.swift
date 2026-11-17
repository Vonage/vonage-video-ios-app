//
//  Created by Vonage on 6/11/25.
//

import CallKit
import Foundation

/// Abstraction over `CXCallController` to enable testing and dependency injection.
///
/// Conformers submit `CXTransaction`s to the system to perform call actions
/// such as start, end, and hold without coupling to the concrete controller.
public protocol CallControllerProtocol {
    func request(_ transaction: CXTransaction) async throws
    func request(_ transaction: CXTransaction, completion: @escaping @Sendable (Error?) -> Void)
}

extension CXCallController: CallControllerProtocol {}

/// Manages CallKit call actions for Vonage video calls.
///
/// `VERACallManager` builds and submits `CXTransaction`s to start, end, and hold calls,
/// keeping the system telephony UI in sync with the app’s call state. It relies on
/// a `CallControllerProtocol` (default: `CXCallController`) for testability.
///
/// ## Responsibilities
/// - Start video calls with a given display handle and call ID
/// - End calls and release CallKit resources
/// - Toggle hold state for ongoing calls
///
/// - SeeAlso: ``ProviderDelegate``
/// - Note: All actions are video-enabled via `CXStartCallAction.isVideo = true`.
open class VERACallManager {

    /// String labels used for internal action tracking or logging.
    enum Call: String {
        case start = "startCall"
        case end = "endCall"
        case hold = "holdCall"
    }

    /// The controller used to submit CallKit transactions.
    let callController: CallControllerProtocol

    /// Creates a call manager.
    ///
    /// - Parameter callController: The controller to request transactions with.
    ///   Defaults to `CXCallController()`.
    public init(callController: CallControllerProtocol = CXCallController()) {
        self.callController = callController
    }

    // MARK: Actions

    /// Starts a video call with the given handle and CallKit identifier.
    ///
    /// - Parameters:
    ///   - handle: A user-visible handle (e.g., room name) shown by CallKit.
    ///   - callID: The `UUID` identifying the CallKit call.
    /// - Throws: An error if the start-call transaction cannot be applied.
    /// - Important: The call is flagged as video by setting `isVideo = true`.
    open func startCall(handle: String, callID: UUID) async throws {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: callID, handle: handle)
        startCallAction.isVideo = true

        let transaction = CXTransaction()
        transaction.addAction(startCallAction)

        try await requestTransaction(transaction, action: Call.start.rawValue)
    }

    /// Ends the call identified by the given `UUID`.
    ///
    /// - Parameter callID: The CallKit call identifier to end.
    /// - Throws: An error if the end-call transaction fails.
    open func end(callID: UUID) async throws {
        let endCallAction = CXEndCallAction(call: callID)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)

        try await requestTransaction(transaction, action: Call.end.rawValue)
    }

    /// Sets the hold state for the specified call.
    ///
    /// - Parameters:
    ///   - callID: The CallKit call identifier to update.
    ///   - onHold: `true` to place on hold; `false` to resume.
    /// - Throws: An error if the set-held transaction fails.
    open func setHeld(callID: UUID, onHold: Bool) async throws {
        let setHeldCallAction = CXSetHeldCallAction(call: callID, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        try await requestTransaction(transaction, action: Call.hold.rawValue)
    }

    /// Sets the microphone mute state for the specified call.
    ///
    /// Uses the completion-based request so it can be called from synchronous
    /// contexts, such as a Combine sink, without an unstructured `Task` that
    /// captures this non-`Sendable` manager.
    ///
    /// - Parameters:
    ///   - callID: The CallKit call identifier to update.
    ///   - isMuted: `true` to show the call as muted; `false` to show it as unmuted.
    ///   - completion: Called with `nil` on success, or the error CallKit returned.
    open func setMuted(callID: UUID, isMuted: Bool, completion: @escaping @Sendable (Error?) -> Void) {
        let setMutedCallAction = CXSetMutedCallAction(call: callID, muted: isMuted)
        let transaction = CXTransaction()
        transaction.addAction(setMutedCallAction)

        callController.request(transaction, completion: completion)
    }

    /// Requests the transaction from the underlying controller.
    ///
    /// - Parameters:
    ///   - transaction: The `CXTransaction` to submit.
    ///   - action: Optional label used for logging or diagnostics.
    /// - Throws: Propagates errors from the underlying controller.
    private func requestTransaction(
        _ transaction: CXTransaction,
        action: String = ""
    ) async throws {
        try await callController.request(transaction)
    }
}
