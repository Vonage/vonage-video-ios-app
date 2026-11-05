//
//  Created by Vonage on 14/7/26.
//

import Foundation
import OpenTok
import Testing
import VERADomain
import VERATestHelpers

@testable import VERAVonage

@Suite("VonagePublisherFactory tests")
@MainActor
struct VonagePublisherFactoryTests {

    private func makeBaseFactory() -> VonagePublisherFactory {
        VonagePublisherFactory(
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase())
    }

    private func makePiPFactory() -> PictureInPictureVonagePublisherFactory {
        PictureInPictureVonagePublisherFactory(
            checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
            checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase())
    }

    @Test("Base factory makes a native (non-PiP) publisher")
    func baseFactoryMakesNative() throws {
        let publisher = try makeBaseFactory().make(PublisherSettings())

        #expect(publisher is VonagePublisher)
        #expect(!(publisher is PictureInPictureVonagePublisher))
    }

    @Test("PiP factory makes a PiP-capable publisher")
    func pipFactoryMakesPiP() throws {
        let publisher = try makePiPFactory().make(PublisherSettings())

        #expect(publisher is PictureInPictureVonagePublisher)
    }

    @Test("New publishers retain saved camera and mirror settings without writing an initial camera change")
    func savedCameraAppliedToEachPublisher() throws {
        let factory = makeBaseFactory()
        var changes: [CameraPosition] = []
        factory.onCameraPositionChanged = { changes.append($0) }
        let settings = PublisherSettings(
            advancedSettings: .init(selfViewMirroringEnabled: false, cameraPosition: .back))
        let first = try #require(try factory.make(settings) as? VonagePublisher)
        let second = try #require(try factory.make(settings) as? VonagePublisher)
        #expect(first.cameraPosition == .back)
        #expect(second.cameraPosition == .back)
        #expect(!first.selfViewMirroringEnabled)
        #expect(!second.selfViewMirroringEnabled)
        #expect(changes.isEmpty)
        first.switchCamera(to: "Front")
        #expect(changes == [.front])
        first.cameraPosition = .front
        #expect(changes == [.front])
    }

    @Test("Factory applies camera content hints to the native capturer", arguments: VideoContentHint.allCases)
    func nativeCameraContentHints(_ hint: VideoContentHint) throws {
        let publisher = try #require(
            try makeBaseFactory().make(PublisherSettings(advancedSettings: .init(cameraContentHint: hint)))
                as? VonagePublisher)
        let capturer = try #require(publisher.otPublisher.videoCapture)
        #expect(capturer.videoContentHint.rawValue == hint.rawValue)
    }

    @Test("Disabled audio effects cannot install noise suppression")
    func audioFeatureFlagIsHonored() throws {
        let factory = makeBaseFactory()
        factory.advancedNoiseSuppressionAvailable = false
        var state: Bool?
        factory.onAdvancedNoiseSuppressionChanged = { state = $0 }
        let publisher = try factory.make(
            PublisherSettings(advancedSettings: .init(advancedNoiseSuppressionEnabled: true)))
        #expect(!publisher.audioTransformers.contains { $0.key == "NoiseSuppression" })
        #expect(state == false)
    }

    @Test("Noise suppression is idempotent and preserves unrelated audio transformers")
    func noiseSuppressionPreservesOtherTransformers() throws {
        let publisher = VonagePublisherSpy()
        let other = MockTransformer(key: "OtherEffect", transformer: NSObject())
        publisher.addAudioTransformer(other)
        try publisher.setAdvancedNoiseSuppression(enabled: true)
        try publisher.setAdvancedNoiseSuppression(enabled: true)
        #expect(publisher.audioTransformers.map(\.key) == ["OtherEffect", "NoiseSuppression"])
        try publisher.setAdvancedNoiseSuppression(enabled: false)
        #expect(publisher.audioTransformers.map(\.key) == ["OtherEffect"])
        #expect((publisher.audioTransformers.first as? MockTransformer) === other)
    }

    @Test("Initial noise state reports UI state without writing a preference change")
    func initialNoiseStateDoesNotRewritePreferences() throws {
        let factory = makeBaseFactory()
        var initialStates: [Bool] = []
        var changes: [Bool] = []
        factory.onAdvancedNoiseSuppressionInitialized = { initialStates.append($0) }
        factory.onAdvancedNoiseSuppressionChanged = { changes.append($0) }
        _ = try factory.make(.init(advancedSettings: .init(advancedNoiseSuppressionEnabled: false)))
        #expect(initialStates == [false])
        #expect(changes.isEmpty)
    }

    @Test("Factory honors publisher settings")
    func factoryHonorsSettings() throws {
        let settings = PublisherSettings(username: "Zaphod", publishAudio: false, publishVideo: false)
        let publisher = try makeBaseFactory().make(settings)

        #expect(publisher is VonagePublisher)
    }
}
