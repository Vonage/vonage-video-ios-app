//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERADomain
import VERATestHelpers
@testable import VERAVonage

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

    /// Records the mode without opening the cameras.
    override func apply(localCameraMode mode: LocalCameraMode) {
        localCameraMode = mode
        otPublisher.cameraPosition = mode == .front ? .front : .back
    }

    override func setVideoTransformers(_ transformers: [any VERATransformer]) {
        super.setVideoTransformers(transformers)
    }

    override func updateVideoTransformers() {
    }

    override func setAudioTransformers(_ transformers: [any VERATransformer]) {
        super.setAudioTransformers(transformers)
    }

    override func updateAudioTransformers() {
    }
}
