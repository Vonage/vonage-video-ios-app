//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERADomain

public final class MockPublisherFactory: PublisherFactory {

    private let mockPublisher: MockVERAPublisher

    public init(mockPublisher: MockVERAPublisher) {
        self.mockPublisher = mockPublisher
    }

    public func make(_ settings: PublisherSettings) -> any VERAPublisher {
        mockPublisher
    }
}
