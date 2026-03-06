//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import VERADomain
import VERATestHelpers
import VERAVonage

public class MockPublisherRepository: PublisherRepository {

    // MARK: - Tracking Properties

    public var recreatePublisherCallCount = 0
    public var recordedSettings: [PublisherSettings] = []
    public var publisherToReturn: VERAPublisher?

    public func getPublisher() -> any VERAPublisher {
        if let publisher = publisherToReturn {
            return publisher
        }
        return VonagePublisher(
            publisher: OTPublisher(delegate: nil)!,
            transformerFactory: MockTransformerFactory()
        )
    }

    public func resetPublisher() {
    }

    public func recreatePublisher(_ settings: PublisherSettings) {
        recreatePublisherCallCount += 1
        recordedSettings.append(settings)
    }
}

public func makeMockPublisherRepository() -> MockPublisherRepository {
    .init()
}
