//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore
import VERADomain

public final class MockVERAPublisherRepository: PublisherRepository {

    public var publisher: MockVERAPublisher!

    public init(publisher: MockVERAPublisher) {
        self.publisher = publisher
    }

    public func getPublisher() -> any VERAPublisher {
        publisher
    }

    public func resetPublisher() {
        publisher = nil
    }

    public func recreatePublisher(_ settings: PublisherSettings) {
        // Do nothing
    }
}

public func makeMockVERAPublisherRepository(
    publisher: MockVERAPublisher = .init()
) -> MockVERAPublisherRepository {
    MockVERAPublisherRepository(publisher: publisher)
}
