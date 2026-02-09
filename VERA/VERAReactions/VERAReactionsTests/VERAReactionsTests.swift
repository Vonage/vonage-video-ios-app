//
//  Created by Vonage on 2/9/26.
//

import XCTest
@testable import VERAReactions

final class VERAReactionsTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(VERAReactions.version, "1.0.0")
    }
}
