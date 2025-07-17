//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore

final class MockVERAPublisherRepository: PublisherRepository {

    let publisher: MockVERAPublisher

    init(publisher: MockVERAPublisher) {
        self.publisher = publisher
    }

    func getPublisher() -> any VERACore.VERAPublisher {
        publisher
    }
}

func makeMockVERAPublisherRepository(
    publisher: MockVERAPublisher = .init()
) -> MockVERAPublisherRepository {
    MockVERAPublisherRepository(publisher: publisher)
}
