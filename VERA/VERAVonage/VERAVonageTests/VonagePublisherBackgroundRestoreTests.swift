//
//  Created by Vonage on 01/06/2026.
//

import Foundation
import OpenTok
import Testing
import UIKit
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("VonagePublisher Background Restore Tests")
struct VonagePublisherBackgroundRestoreTests {

    @Test("Given transformers are set, when app becomes active, then transformers are re-synced")
    func resyncTransformersOnDidBecomeActive() {
        let sut = TrackingVonagePublisherSpy()
        let transformer = MockTransformer(key: "blur", transformer: NSObject())
        sut.setVideoTransformers([transformer])

        let initialCount = sut.updateVideoTransformersCallCount

        NotificationCenter.default.post(
            name: UIApplication.didBecomeActiveNotification, object: nil)

        #expect(sut.updateVideoTransformersCallCount == initialCount + 1)
    }

    @Test("Given no transformers, when app becomes active, then nothing is re-synced")
    func noResyncWhenNoTransformers() {
        let sut = TrackingVonagePublisherSpy()

        let initialCount = sut.updateVideoTransformersCallCount

        NotificationCenter.default.post(
            name: UIApplication.didBecomeActiveNotification, object: nil)

        #expect(sut.updateVideoTransformersCallCount == initialCount)
    }

    @Test("Given transformers are set and cleanUp is called, when app becomes active, then nothing is re-synced")
    func noResyncAfterCleanUp() {
        let sut = TrackingVonagePublisherSpy()
        let transformer = MockTransformer(key: "blur", transformer: NSObject())
        sut.setVideoTransformers([transformer])

        sut.cleanUp()
        let countAfterCleanUp = sut.updateVideoTransformersCallCount

        NotificationCenter.default.post(
            name: UIApplication.didBecomeActiveNotification, object: nil)

        #expect(sut.updateVideoTransformersCallCount == countAfterCleanUp)
    }
}

// MARK: - Test Spy

private class TrackingVonagePublisherSpy: VonagePublisher {
    var updateVideoTransformersCallCount = 0

    init() {
        super.init(
            publisher: OTPublisher(delegate: nil)!,
            transformerFactory: MockTransformerFactory())
    }

    override func updateVideoTransformers() {
        updateVideoTransformersCallCount += 1
    }
}
