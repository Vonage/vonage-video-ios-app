//
//  Created by Vonage on 28/7/25.
//

import Foundation
import OpenTok

open class OpenTokSession: NSObject, OTSessionDelegate, OpenTokSignalChannel {
    private let session: OTSession

    var onSessionDidConnect: (() -> Void)?
    var onSessionDidDisconnect: (() -> Void)?
    var onSessionFailure: ((Error) -> Void)?
    public var onNewStream: ((OTStream) -> Void)?
    var onStreamDestroyed: ((OTStream) -> Void)?
    var onSessionSignal: ((OpenTokSignal) -> Void)?

    public init(session: OTSession) {
        self.session = session
    }

    open func connect(with token: String) throws {
        assertMainThread()
        var error: OTError?
        session.connect(withToken: token, error: &error)
        if let error = error {
            throw error
        }
    }

    open func disconnect() throws {
        assertMainThread()
        var error: OTError?
        session.disconnect(&error)

        if let error = error {
            throw error
        }
    }

    public func session(_ session: OTSession, didFailWithError error: OTError) {
        onSessionFailure?(error)
    }

    public func session(_ session: OTSession, streamCreated stream: OTStream) {
        onNewStream?(stream)
    }

    public func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        onStreamDestroyed?(stream)
    }

    public func sessionDidConnect(_ session: OTSession) {
        onSessionDidConnect?()
    }

    public func sessionDidDisconnect(_ session: OTSession) {
        onSessionDidDisconnect?()
    }

    public func subscribe(subscriber: OpenTokSubscriber) throws {
        assertMainThread()
        var error: OTError?
        let _subscriber: OTSubscriberKit = subscriber.otSubscriber
        session.subscribe(_subscriber, error: &error)

        if let error = error {
            throw error
        }
    }

    public func unsubscribe(subscriber: OpenTokSubscriber) throws {
        assertMainThread()

        var error: OTError?
        session.unsubscribe(subscriber.otSubscriber, error: &error)

        if let error = error {
            throw error
        }
    }

    public func publish(publisher: OpenTokPublisher) throws {
        assertMainThread()
        var error: OTError?
        session.publish(publisher.otPublisher, error: &error)

        if let error = error {
            throw error
        }
    }

    public func unpublish(publisher: OpenTokPublisher) throws {
        assertMainThread()

        var error: OTError?
        session.unpublish(publisher.otPublisher, error: &error)

        if let error = error {
            throw error
        }
    }

    // MARK: Signals

    public func session(
        _ session: OTSession,
        receivedSignalType type: String?,
        from connection: OTConnection?,
        with string: String?
    ) {
        guard let type = type else { return }

        onSessionSignal?(.init(type: type, data: string))
    }

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

    func cleanUp() {
        onSessionDidConnect = nil
        onSessionDidDisconnect = nil
        onSessionFailure = nil
        onNewStream = nil
        onStreamDestroyed = nil
        onSessionSignal = nil
    }
}
