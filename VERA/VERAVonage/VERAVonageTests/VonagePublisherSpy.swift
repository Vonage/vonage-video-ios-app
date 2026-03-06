//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERADomain
import VERATestHelpers
import VERAVonage

class VonagePublisherSpy: VonagePublisher {
    var cleanUpCallCount = 0

    var exposedOTPublisher: OTPublisher {
        otPublisher
    }

    init() {
        super.init(
            publisher: OTPublisher(delegate: nil)!,
            transformerFactory: MockTransformerFactory())
    }

    override func cleanUp() {
        cleanUpCallCount += 1
        super.cleanUp()
    }

    override func setVideoTransformers(_ transformers: [any VERATransformer]) {
        super.setVideoTransformers(transformers)
    }

    override func updateVideoTransformers() {}
}
