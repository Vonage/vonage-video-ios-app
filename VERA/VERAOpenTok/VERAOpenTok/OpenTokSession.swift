//
//  Created by Vonage on 28/7/25.
//

import Foundation
import OpenTok

open class OpenTokSession: NSObject, OTSessionDelegate {
    private let session: OTSession

    var onSessionDidConnect: (() -> Void)?
    var onSessionDidDisconnect: (() -> Void)?
    var onSessionFailure: ((Error) -> Void)?
    public var onNewStream: ((OTStream) -> Void)?
    var onStreamDestroyed: ((OTStream) -> Void)?

    public init(session: OTSession) {
        self.session = session
    }

    open func connect(with token: String) throws {
        assertMainThread()
        print("Connect to session")
        var error: OTError?
        session.connect(withToken: token, error: &error)
        print("Connected to session error \(error?.localizedDescription ?? "none")")
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
        print("session didFailWithError \(error.localizedDescription)")
        onSessionFailure?(error)
    }

    public func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("session streamCreated \(stream.streamId)")
        onNewStream?(stream)
    }

    public func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("session streamDestroyed \(stream.streamId)")
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
        print("Subscribing \(subscriber.id)")
        session.subscribe(_subscriber, error: &error)
        print("Subscribed \(subscriber.id) \(error?.localizedDescription ?? "no error")")

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
}
