//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import VERACore
import VERAVonage

public class MockPublisherRepository: PublisherRepository {

    public func getPublisher() -> any VERACore.VERAPublisher {
        VonagePublisher(publisher: OTPublisher(delegate: nil)!)
    }

    public func resetPublisher() {
    }

    public func recreatePublisher(_ settings: VERACore.PublisherSettings) {
    }
}

public func makeMockPublisherRepository() -> MockPublisherRepository {
    .init()
}
