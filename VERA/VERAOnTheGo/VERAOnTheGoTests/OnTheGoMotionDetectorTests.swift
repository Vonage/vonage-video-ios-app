//
//  Created by Vonage on 17/10/26.
//

import Foundation
import Testing

@testable import VERAOnTheGo

@Suite("OnTheGoMotionDetector Tests")
struct OnTheGoMotionDetectorTests {

    @Test("Moving for the full 20 s threshold fires exactly once")
    func sustainedMotionFires() {
        var fireCount = 0
        let detector = OnTheGoMotionDetector()
        detector.onSustainedMotion = { fireCount += 1 }

        for second in stride(from: 0.0, through: 20.0, by: 5) {
            detector.ingest(.make(at: second))
        }

        #expect(fireCount == 1)
        #expect(detector.hasFired)
    }

    @Test("19 s of motion does not fire")
    func subThresholdDoesNotFire() {
        var fired = false
        let detector = OnTheGoMotionDetector()
        detector.onSustainedMotion = { fired = true }

        for second in stride(from: 0.0, through: 19.0, by: 5) {
            detector.ingest(.make(at: second))
        }

        #expect(!fired)
    }

    @Test("A stationary sample resets the run")
    func stationaryResets() {
        var fired = false
        let detector = OnTheGoMotionDetector()
        detector.onSustainedMotion = { fired = true }

        detector.ingest(.make(at: 0))
        detector.ingest(.make(at: 15))
        detector.ingest(.make(kind: .stationary, at: 16))
        detector.ingest(.make(at: 17))
        detector.ingest(.make(at: 35))

        #expect(!fired)

        detector.ingest(.make(at: 37))

        #expect(fired)
    }

    @Test("Low-confidence samples never count as motion")
    func lowConfidenceNeverFires() {
        var fired = false
        let detector = OnTheGoMotionDetector()
        detector.onSustainedMotion = { fired = true }

        for second in stride(from: 0.0, through: 60.0, by: 5) {
            detector.ingest(.make(confidence: .low, at: second))
        }

        #expect(!fired)
    }

    @Test("After firing, further samples are ignored")
    func noRefire() {
        var fireCount = 0
        let detector = OnTheGoMotionDetector()
        detector.onSustainedMotion = { fireCount += 1 }

        for second in stride(from: 0.0, through: 60.0, by: 5) {
            detector.ingest(.make(at: second))
        }

        #expect(fireCount == 1)
    }

    @Test("reset() allows firing again")
    func resetAllowsRefire() {
        var fireCount = 0
        let detector = OnTheGoMotionDetector()
        detector.onSustainedMotion = { fireCount += 1 }

        for second in stride(from: 0.0, through: 20.0, by: 5) {
            detector.ingest(.make(at: second))
        }
        #expect(fireCount == 1)

        detector.reset()
        #expect(!detector.hasFired)

        for second in stride(from: 100.0, through: 120.0, by: 5) {
            detector.ingest(.make(at: second))
        }
        #expect(fireCount == 2)
    }

    @Test("An unknown-activity sample resets the run")
    func unknownResets() {
        var fired = false
        let detector = OnTheGoMotionDetector()
        detector.onSustainedMotion = { fired = true }

        detector.ingest(.make(at: 0))
        detector.ingest(.make(kind: .unknown, at: 10))
        detector.ingest(.make(at: 15))
        detector.ingest(.make(at: 30))

        #expect(!fired)
    }
}
