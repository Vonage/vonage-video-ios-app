//
//  Created by Vonage on 24/9/25.
//

import Foundation
import Testing
import VERACore

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

    // MARK: - SUT Factory

    func makeSUT(navigator: Navigator) -> HandleUniversalLink {
        HandleUniversalLink(baseURL: baseURL, navigator: navigator)
    }
}
