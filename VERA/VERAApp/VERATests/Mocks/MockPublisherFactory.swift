//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERACore

final class MockPublisherFactory: PublisherFactory {

    private let mockPublisher: MockVERAPublisher

    init(mockPublisher: MockVERAPublisher) {
        self.mockPublisher = mockPublisher
    }

    func make() -> any VERACore.VERAPublisher {
        mockPublisher
    }
}
