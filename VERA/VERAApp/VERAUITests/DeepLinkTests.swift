//
//  Created by Vonage on 24/9/25.
//

import XCTest

@testable import VERA

class DeepLinkTests: XCTestCase {

    var appDelegate: AppDelegate!

    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }

    func testMeetingDeepLink() {
        // Given
        let url = URL(string: "https://yourdomain.com/meeting/123")!
        let options: [UIApplication.OpenURLOptionsKey: Any] = [:]

        // When
        let result = appDelegate.application(UIApplication.shared, open: url, options: options)

        // Then
        XCTAssertTrue(result, "App should handle meeting deep link")
    }

    func testInvalidDeepLink() {
        // Given
        let url = URL(string: "https://otherdomain.com/meeting/123")!
        let options: [UIApplication.OpenURLOptionsKey: Any] = [:]

        // When
        let result = appDelegate.application(UIApplication.shared, open: url, options: options)

        // Then
        XCTAssertFalse(result, "App should reject invalid domain")
    }

    func testDeepLinkParsing() {
        // Given
        let url = URL(string: "https://yourdomain.com/meeting/123?token=abc")!

        // When
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // Then
        XCTAssertEqual(components?.path, "/meeting/123")
        XCTAssertEqual(components?.queryItems?.first { $0.name == "token" }?.value, "abc")
    }
}
