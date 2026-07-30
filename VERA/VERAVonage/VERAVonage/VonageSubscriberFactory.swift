//
//  Created by Vonage on 25/9/25.
//

import Foundation
import OpenTok

/// Creates standard subscribers that render through OpenTok's native view.
///
/// Subclass and override ``makeVonageSubscriber(_:)`` to vary the subscriber family; see
/// ``PictureInPictureVonageSubscriberFactory``. The composition root picks the concrete factory, so
/// the PiP-vs-native choice is made once rather than branched on a flag.
class VonageSubscriberFactory {

    enum Error: Swift.Error {
        case subscriberCreationFailed
    }

    func makeSubscriber(_ stream: OTStream) throws -> VonageSubscriber {
        guard let subscriber = OTSubscriber(stream: stream, delegate: nil) else {
            throw Error.subscriberCreationFailed
        }
        let vonageSubscriber = makeVonageSubscriber(subscriber)
        vonageSubscriber.setup()
        subscriber.delegate = vonageSubscriber
        subscriber.audioLevelDelegate = vonageSubscriber
        subscriber.captionsDelegate = vonageSubscriber

        return vonageSubscriber
    }

    func makeVonageSubscriber(_ subscriber: OTSubscriber) -> VonageSubscriber {
        VonageSubscriber(subscriber: subscriber)
    }
}

/// Creates subscribers that render through the PiP-capable custom renderer.
final class PictureInPictureVonageSubscriberFactory: VonageSubscriberFactory {
    override func makeVonageSubscriber(_ subscriber: OTSubscriber) -> VonageSubscriber {
        PictureInPictureVonageSubscriber(subscriber: subscriber)
    }
}
