//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERAVonageArchivingPlugin

@Suite("Vonage Archiving Plugin tests")
struct VonageArchivingPluginTests {

    @Test func zero() async throws {
    }

    // MARK: SUT

    func makeSUT() -> VonageArchivingPlugin {
        VonageArchivingPlugin()
    }
}

extension AnyPublisher where Failure == Never {
    func nextValue() async -> Output {
        await values.first { _ in true }!
    }
}
