//
//  Created by Vonage on 24/9/26.
//

import OpenTok
import Testing
import VERADomain

@testable import VERAVonage

@Suite("VonageSession tests")
struct VonageSessionTests {

    // MARK: - Metadata

    @Test("roomName exposes the credentials room name")
    func roomNameExposesCredentialsRoomName() {
        let sut = makeSUT(roomName: "heart-of-gold")

        #expect(sut.roomName == "heart-of-gold")
    }

    // MARK: - Delegate: errors & streams

    @Test("didFailWithError forwards the error to onSessionFailure")
    func didFailWithErrorForwardsToCallback() {
        let sut = makeSUT()
        var receivedError: Error?
        sut.onSessionFailure = { receivedError = $0 }

        let error = OTError(domain: OT_SESSION_ERROR_DOMAIN, code: 1500, userInfo: nil)
        sut.session(makeOTSession(), didFailWithError: error)

        #expect(receivedError != nil)
    }

    @Test("streamCreated forwards the stream to onNewStream")
    func streamCreatedForwardsToCallback() {
        let sut = makeSUT()
        var didReceiveStream = false
        sut.onNewStream = { _ in didReceiveStream = true }

        sut.session(makeOTSession(), streamCreated: OTStream())

        #expect(didReceiveStream)
    }

    @Test("streamDestroyed forwards the stream to onStreamDestroyed")
    func streamDestroyedForwardsToCallback() {
        let sut = makeSUT()
        var didDestroyStream = false
        sut.onStreamDestroyed = { _ in didDestroyStream = true }

        sut.session(makeOTSession(), streamDestroyed: OTStream())

        #expect(didDestroyStream)
    }

    // MARK: - Delegate: lifecycle

    @Test("sessionDidConnect forwards to onSessionDidConnect")
    func sessionDidConnectForwardsToCallback() {
        let sut = makeSUT()
        var didConnect = false
        sut.onSessionDidConnect = { didConnect = true }

        sut.sessionDidConnect(makeOTSession())

        #expect(didConnect)
    }

    @Test("sessionDidDisconnect forwards to onSessionDidDisconnect")
    func sessionDidDisconnectForwardsToCallback() {
        let sut = makeSUT()
        var didDisconnect = false
        sut.onSessionDidDisconnect = { didDisconnect = true }

        sut.sessionDidDisconnect(makeOTSession())

        #expect(didDisconnect)
    }

    @Test("sessionDidReconnect forwards to onSessionDidReconnect")
    func sessionDidReconnectForwardsToCallback() {
        let sut = makeSUT()
        var didReconnect = false
        sut.onSessionDidReconnect = { didReconnect = true }

        sut.sessionDidReconnect(makeOTSession())

        #expect(didReconnect)
    }

    @Test("sessionDidBeginReconnecting forwards to onSessionDidBeginReconnecting")
    func sessionDidBeginReconnectingForwardsToCallback() {
        let sut = makeSUT()
        var didBeginReconnecting = false
        sut.onSessionDidBeginReconnecting = { didBeginReconnecting = true }

        sut.sessionDidBeginReconnecting(makeOTSession())

        #expect(didBeginReconnecting)
    }

    // MARK: - Publishing / Subscribing / Disconnect

    @Test("disconnect delegates to the SDK session without crashing")
    func disconnectDelegatesToSDK() {
        let sut = makeSUT()

        #expect(throws: Never.self) {
            try? sut.disconnect()
        }
    }

    @Test("publish delegates to the SDK session without crashing")
    func publishDelegatesToSDK() {
        let sut = makeSUT()
        let publisher = VonagePublisherSpy()

        #expect(throws: Never.self) {
            try? sut.publish(publisher: publisher)
        }
    }

    @Test("unpublish delegates to the SDK session without crashing")
    func unpublishDelegatesToSDK() {
        let sut = makeSUT()
        let publisher = VonagePublisherSpy()

        #expect(throws: Never.self) {
            try? sut.unpublish(publisher: publisher)
        }
    }

    @Test("subscribe delegates to the SDK session without crashing")
    func subscribeDelegatesToSDK() {
        let sut = makeSUT()

        guard let subscriber = try? VonageSubscriberFactory().makeSubscriber(OTStream()) else { return }

        #expect(throws: Never.self) {
            try? sut.subscribe(subscriber: subscriber)
        }
    }

    @Test("unsubscribe delegates to the SDK session without crashing")
    func unsubscribeDelegatesToSDK() {
        let sut = makeSUT()
        guard let subscriber = try? VonageSubscriberFactory().makeSubscriber(OTStream()) else { return }

        #expect(throws: Never.self) {
            try? sut.unsubscribe(subscriber: subscriber)
        }
    }

    // MARK: - Helpers

    private func makeSUT(roomName: String = "aRoomName") -> VonageSession {
        VonageSession(
            session: makeOTSession(),
            credentials: RoomCredentials(
                sessionId: "sessionId",
                token: "token",
                applicationId: "applicationId",
                roomName: roomName,
                sessionKey: "sessionKey"))
    }

    private func makeOTSession() -> OTSession {
        OTSession(applicationId: "applicationId", sessionId: "sessionId", delegate: nil)!
    }
}
