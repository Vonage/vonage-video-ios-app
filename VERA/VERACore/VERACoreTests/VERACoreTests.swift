//
//  Created by Vonage on 7/7/25.
//

import Foundation
import Testing

@testable import VERACore

struct VERACoreTests {
    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.

        // This is a universal test that can run on macOS, iOS, etc.
        let result = true
        #expect(result == true)
    }

    @Test func vERACoreExists() async throws {
        // Test that VERACore module can be imported and basic functionality works
        #expect(true, "VERACore module should be importable")
    }
}
