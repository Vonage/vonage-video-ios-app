//
//  Created by Vonage on 24/9/25.
//

import Foundation
import Testing
import VERACore
import VERADomain

@testable import VERA

@MainActor
@Suite("HandleUniversalLink tests")
struct HandleUniversalLinkTests {

    let baseURL = URL(string: "https://video.vonage.com")!

    // MARK: - Parametrized Test

    @MainActor
    @Test(
        "Universal Link Handling",
        arguments: [
            // Valid cases
            ("https://video.vonage.com/room/heart-of-gold", [AppRoute.waitingRoom("heart-of-gold")]),
            ("https://video.vonage.com/waiting-room/test-room", [AppRoute.waitingRoom("test-room")]),
            ("https://video.vonage.com/room/my_room_name", [AppRoute.waitingRoom("my_room_name")]),
            ("https://video.vonage.com/waiting-room/room-123", [AppRoute.waitingRoom("room-123")]),
            ("https://video.vonage.com/room/a", [AppRoute.waitingRoom("a")]),
            ("https://video.vonage.com/room/heart-of-gold?param=value", [AppRoute.waitingRoom("heart-of-gold")]),
            ("https://video.vonage.com/room/heart-of-gold#section", [AppRoute.waitingRoom("heart-of-gold")]),

            // Invalid cases
            ("https://other-domain.com/room/test", []),  // Wrong domain
            ("https://video.vonage.com/invalid/path", []),  // Wrong path
            ("https://video.vonage.com/room/", []),  // Empty room name
            ("https://video.vonage.com/waiting-room/", []),  // Empty room name
            ("https://video.vonage.com/", []),  // Root path
            ("https://video.vonage.com", []),  // No path
        ]
    )
    func universalLinkHandling(
        urlString: String,
        expectedRoutes: [AppRoute]
    ) async throws {
        // Given
        let targetURL = URL(string: urlString)!
        let spy = NavigationCoordinatorSpy()

        // When
        let sut = makeSUT(navigator: spy)
        sut(targetURL)

        // Then
        #expect(
            spy.navigationRoutes == expectedRoutes,
            "Expected \(expectedRoutes) but got \(spy.navigationRoutes) for URL: \(urlString)")
    }

    // MARK: - Session Key Deep Link

    @MainActor
    @Test(
        "Session key JWT in URL path navigates to waiting room",
        arguments: [
            ("https://video.vonage.com/room", AppRoute.waitingRoom("heart-of-gold")),
            ("https://video.vonage.com/waiting-room", AppRoute.waitingRoom("heart-of-gold")),
        ])
    func sessionKeyDeepLink(
        urlString: String,
        expectedRoute: AppRoute
    ) {
        // Construct a JWT-like token at runtime
        let sessionKey = makeTestSessionKey()
        let urlString = "\(urlString)/\(sessionKey)"
        let targetURL = URL(string: urlString)!
        let spy = NavigationCoordinatorSpy()

        let sut = makeSUT(navigator: spy)
        sut(targetURL)

        #expect(spy.navigationRoutes == [expectedRoute])
    }

    @MainActor
    @Test("Expired session key JWT in URL does not navigate and shows an alert")
    func expiredSessionKeyDeepLinkDoesNotNavigate() {
        let pastExp = Date().addingTimeInterval(-3600).timeIntervalSince1970
        let sessionKey = makeTestSessionKey(extraClaims: ["exp": pastExp])
        let targetURL = URL(string: "https://video.vonage.com/waiting-room/\(sessionKey)")!
        let spy = NavigationCoordinatorSpy()

        let sut = makeSUT(navigator: spy)
        sut(targetURL)

        #expect(spy.navigationRoutes == [])
        #expect(spy.alerts.map(\.title) == ["Link Expired"])
    }

    @MainActor
    @Test("Expired scheduled session key (schedule.endsAtMs) in URL does not navigate and shows an alert")
    func expiredScheduledSessionKeyDeepLinkDoesNotNavigate() {
        let pastEndsAtMs = Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000
        let sessionKey = makeTestSessionKey(
            extraClaims: ["schedule": ["startsAtMs": pastEndsAtMs - 3_600_000, "endsAtMs": pastEndsAtMs]])
        let targetURL = URL(string: "https://video.vonage.com/waiting-room/\(sessionKey)")!
        let spy = NavigationCoordinatorSpy()

        let sut = makeSUT(navigator: spy)
        sut(targetURL)

        #expect(spy.navigationRoutes == [])
        #expect(spy.alerts.map(\.title) == ["Link Expired"])
    }

    // MARK: - SUT Factory

    func makeSUT(navigator: Navigator) -> HandleUniversalLink {
        HandleUniversalLink(baseURL: baseURL, navigator: navigator)
    }

    private func makeTestSessionKey(extraClaims: [String: Any] = [:]) -> String {
        var payloadClaims: [String: Any] = ["sessionId": "1_MX4x", "roomName": "heart-of-gold", "iat": 1_776_844_771]
        payloadClaims.merge(extraClaims) { _, new in new }

        let header = Data("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".utf8).base64URLEncoded
        let payloadData = (try? JSONSerialization.data(withJSONObject: payloadClaims)) ?? Data()
        let payload = payloadData.base64URLEncoded
        let signature = Data("test-signature".utf8).base64URLEncoded
        return "\(header).\(payload).\(signature)"
    }
}

extension Data {
    fileprivate var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
