//
//  Created by Vonage on 28/7/25.
//

import Foundation
import OpenTok

/// A thin wrapper around `OTSession` that manages connection lifecycle, stream events, and signaling.
///
/// `OpenTokSession` centralizes interaction with the OpenTok SDK’s session object, exposing
/// typed callbacks for connection, streams, failures, and custom signals. It provides convenience
/// methods for connecting, publishing, subscribing, and emitting signals in a safer Swift API.
///
/// ## Overview
///
/// Use this class to:
/// - Connect and disconnect from an OpenTok session
/// - Publish/unpublish the local `OpenTokPublisher`
/// - Subscribe/unsubscribe `OpenTokSubscriber` instances
/// - Receive session events via callback closures
/// - Send and receive custom OpenTok signals
///
/// Internally, it delegates to `OTSession` and forwards OpenTok delegate events to your
/// closures so you can compose higher-level behaviors elsewhere (e.g., in your call façade).
open class OpenTokSession: NSObject, OTSessionDelegate, OpenTokSignalChannel {
    private let session: OTSession

    /// Called when the session successfully connects.
    ///
    /// Use this to kick off post-connection actions like publishing the local stream.
    var onSessionDidConnect: (() -> Void)?

    /// Called when the session disconnects.
    ///
    /// Use this to clean up state and UI.
    var onSessionDidDisconnect: (() -> Void)?

    /// Called when the session reports a failure.
    ///
    /// - Parameter error: The underlying `OTError` describing the failure.
    var onSessionFailure: ((Error) -> Void)?

    /// Called when a new remote stream is created in the session.
    ///
    /// - Parameter stream: The newly available `OTStream` to which you can subscribe.
    public var onNewStream: ((OTStream) -> Void)?

    /// Called when a remote stream is destroyed (no longer available).
    ///
    /// - Parameter stream: The `OTStream` that was destroyed.
    var onStreamDestroyed: ((OTStream) -> Void)?

    /// Called when a custom OpenTok signal is received.
    ///
    /// - Parameter signal: An ``OpenTokSignal`` containing the signal type and optional payload.
    var onSessionSignal: ((OpenTokSignal) -> Void)?

    /// Creates a new session wrapper.
    ///
    /// - Parameter session: A configured `OTSession` instance.
    public init(session: OTSession) {
        self.session = session
    }

    /// Connects to the OpenTok session using the provided token.
    ///
    /// - Parameter token: A valid OpenTok token associated with the session.
    /// - Throws: An `OTError` when the connection operation fails.
    ///
    /// ## Implementation Details
    /// Delegates to `OTSession.connect(withToken:error:)` and throws if an error is returned.
    open func connect(with token: String) throws {
        var error: OTError?
        session.connect(withToken: token, error: &error)
        if let error = error {
            throw error
        }
    }

    /// Disconnects from the OpenTok session.
    ///
    /// - Throws: An `OTError` when the disconnect operation fails.
    ///
    /// ## Implementation Details
    /// Delegates to `OTSession.disconnect(_:)` and throws if an error is returned.
    open func disconnect() throws {
        var error: OTError?
        session.disconnect(&error)

        if let error = error {
            throw error
        }
    }

    // MARK: Delegate: Errors

    /// OpenTok session delegate method called on unrecoverable error.
    ///
    /// Forwards the error to ``onSessionFailure``.
    public func session(_ session: OTSession, didFailWithError error: OTError) {
        onSessionFailure?(error)
    }

    // MARK: Delegate: Streams

    /// OpenTok session delegate method called when a new remote stream is created.
    ///
    /// Forwards the stream to ``onNewStream``.
    public func session(_ session: OTSession, streamCreated stream: OTStream) {
        onNewStream?(stream)
    }

    /// OpenTok session delegate method called when a remote stream is destroyed.
    ///
    /// Forwards the stream to ``onStreamDestroyed``.
    public func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        onStreamDestroyed?(stream)
    }

    // MARK: Delegate: Lifecycle

    /// OpenTok session delegate method called when the session connects.
    ///
    /// Forwards to ``onSessionDidConnect``.
    public func sessionDidConnect(_ session: OTSession) {
        onSessionDidConnect?()
    }

    /// OpenTok session delegate method called when the session disconnects.
    ///
    /// Forwards to ``onSessionDidDisconnect``.
    public func sessionDidDisconnect(_ session: OTSession) {
        onSessionDidDisconnect?()
    }

    // MARK: Publishing/Subscribing

    /// Subscribes the provided subscriber to the session.
    ///
    /// - Parameter subscriber: The ``OpenTokSubscriber`` to attach to the session.
    /// - Throws: An `OTError` when the subscribe operation fails.
    ///
    /// ## Implementation Details
    /// Delegates to `OTSession.subscribe(_:error:)`.
    public func subscribe(subscriber: OpenTokSubscriber) throws {
        var error: OTError?
        session.subscribe(subscriber.otSubscriber, error: &error)

        if let error = error {
            throw error
        }
    }

    /// Unsubscribes the provided subscriber from the session.
    ///
    /// - Parameter subscriber: The ``OpenTokSubscriber`` to detach from the session.
    /// - Throws: An `OTError` when the unsubscribe operation fails.
    ///
    /// ## Implementation Details
    /// Delegates to `OTSession.unsubscribe(_:error:)`.
    public func unsubscribe(subscriber: OpenTokSubscriber) throws {
        var error: OTError?
        session.unsubscribe(subscriber.otSubscriber, error: &error)

        if let error = error {
            throw error
        }
    }

    /// Publishes the local media stream to the session.
    ///
    /// - Parameter publisher: The ``OpenTokPublisher`` whose stream should be published.
    /// - Throws: An `OTError` when the publish operation fails.
    ///
    /// ## Implementation Details
    /// Delegates to `OTSession.publish(_:error:)`.
    public func publish(publisher: OpenTokPublisher) throws {
        var error: OTError?
        session.publish(publisher.otPublisher, error: &error)

        if let error = error {
            throw error
        }
    }

    /// Unpublishes the local media stream from the session.
    ///
    /// - Parameter publisher: The ``OpenTokPublisher`` whose stream should be unpublised.
    /// - Throws: An `OTError` when the unpublish operation fails.
    ///
    /// ## Implementation Details
    /// Delegates to `OTSession.unpublish(_:error:)`.
    public func unpublish(publisher: OpenTokPublisher) throws {
        var error: OTError?
        session.unpublish(publisher.otPublisher, error: &error)

        if let error = error {
            throw error
        }
    }

    // MARK: Signals

    /// OpenTok session delegate method called when a signal is received.
    ///
    /// Converts the incoming signal into an ``OpenTokSignal`` and forwards to ``onSessionSignal``.
    public func session(
        _ session: OTSession,
        receivedSignalType type: String?,
        from connection: OTConnection?,
        with string: String?
    ) {
        guard let type = type else { return }

        onSessionSignal?(.init(type: type, data: string))
    }

    /// Emits a custom OpenTok signal to the session.
    ///
    /// - Parameter signal: An ``OutgoingSignal`` with a type and payload.
    /// - Throws: An `OTError` when the signal operation fails.
    ///
    /// ## Implementation Details
    /// Delegates to `OTSession.signal(withType:string:connection:error:)` and throws on failure.
    public func emitSignal(_ signal: OutgoingSignal) throws {
        var error: OTError?
        session.signal(
            withType: signal.type,
            string: signal.payload,
            connection: nil,
            error: &error)

        if let error = error {
            throw error
        }
    }

    // MARK: Clean up

    /// Clears all session callbacks to prevent retain cycles and further event delivery.
    ///
    /// Call when tearing down the session wrapper or after disconnecting and releasing resources.
    func cleanUp() {
        onSessionDidConnect = nil
        onSessionDidDisconnect = nil
        onSessionFailure = nil
        onNewStream = nil
        onStreamDestroyed = nil
        onSessionSignal = nil
    }
}
