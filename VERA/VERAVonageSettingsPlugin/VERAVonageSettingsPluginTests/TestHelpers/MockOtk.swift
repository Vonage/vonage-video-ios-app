//
//  Created by Vonage on 06/03/2026.
//

import OpenTok

// Note: We don't mock OTSubscriberKit because it requires an OTStream which cannot be easily mocked
// Instead, we use a dummy reference variable in tests
var dummySubscriber: OTSubscriberKit {
    unsafeBitCast(0 as Int, to: OTSubscriberKit.self)
}

class MockPublisher: OTPublisherKit {
    init() {
        super.init(delegate: nil, settings: OTPublisherKitSettings())!
    }
}
