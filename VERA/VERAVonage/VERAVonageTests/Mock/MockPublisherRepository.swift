//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import VERADomain
import VERATestHelpers
import VERAVonage

public class MockPublisherRepository: PublisherRepository {

    public func getPublisher() -> any VERAPublisher {
        VonagePublisher(
            publisher: OTPublisher(delegate: nil)!,
            transformerFactory: MockTransformerFactory()
        )
    }

    public func resetPublisher() {
    }

    public func recreatePublisher(_ settings: PublisherSettings) {
    }
}

public func makeMockPublisherRepository() -> MockPublisherRepository {
    .init()
}
