//
//  Created by Vonage on 25/9/25.
//

import Foundation
import OpenTok

final class VonageSubscriberFactory {

    enum Error: Swift.Error {
        case subscriberCreationFailed
    }

    func makeSubscriber(_ stream: OTStream) throws -> VonageSubscriber {

        guard let subscriber = OTSubscriber(stream: stream, delegate: nil) else {
            throw Error.subscriberCreationFailed
        }
        let vonageSubscriber = VonageSubscriber(subscriber: subscriber)
        vonageSubscriber.setup()
        subscriber.delegate = vonageSubscriber
        subscriber.audioLevelDelegate = vonageSubscriber
        subscriber.captionsDelegate = vonageSubscriber

        return vonageSubscriber
    }
}
