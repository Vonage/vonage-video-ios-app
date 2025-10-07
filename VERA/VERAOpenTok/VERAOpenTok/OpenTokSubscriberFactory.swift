//
//  Created by Vonage on 25/9/25.
//

import Foundation
import OpenTok

final class OpenTokSubscriberFactory {

    enum Error: Swift.Error {
        case subscriberCreationFailed
    }

    func makeSubscriber(_ stream: OTStream) throws -> OpenTokSubscriber {

        guard let subscriber = OTSubscriber(stream: stream, delegate: nil) else {
            throw Error.subscriberCreationFailed
        }
        let openTokSubscriber = OpenTokSubscriber(subscriber: subscriber)
        openTokSubscriber.setup()
        subscriber.delegate = openTokSubscriber
        subscriber.audioLevelDelegate = openTokSubscriber
        subscriber.captionsDelegate = openTokSubscriber

        return openTokSubscriber
    }
}
