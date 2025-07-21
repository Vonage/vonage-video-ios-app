//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore

final class MockVERAPublisherRepository: PublisherRepository {

    var publisher: MockVERAPublisher!

    init(publisher: MockVERAPublisher) {
        self.publisher = publisher
    }

    func getPublisher() -> any VERACore.VERAPublisher {
        publisher
    }

    func resetPublisher() {
        publisher = nil
    }

    func recreatePublisher(_ settings: PublisherSettings) {
        // Do nothing
    }
}

func makeMockVERAPublisherRepository(
    publisher: MockVERAPublisher = .init()
) -> MockVERAPublisherRepository {
    MockVERAPublisherRepository(publisher: publisher)
}
