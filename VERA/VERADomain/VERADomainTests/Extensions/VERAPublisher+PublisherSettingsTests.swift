//
//  Created by Vonage on 24/04/2026.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERADomain

@Suite("VERAPublisher+PublisherSettings tests")
struct VERAPublisherPublisherSettingsTests {

    @Test("Given default parameters, publisherSettings returns settings with empty username and no advanced settings")
    func publisherSettingsReturnsDefaultSettings() {
        let sut = makeMockPublisher(publishAudio: true, publishVideo: true)

        let settings = sut.publisherSettings()

        #expect(settings.username == "")
        #expect(settings.publishAudio == true)
        #expect(settings.publishVideo == true)
        #expect(settings.advancedSettings == nil)
    }

    @Test("Given a username, publisherSettings embeds that username in the result")
    func publisherSettingsEmbedUsername() {
        let sut = makeMockPublisher()

        let settings = sut.publisherSettings(username: "Alice")

        #expect(settings.username == "Alice")
    }

    @Test("Given publisher with publishAudio false, publisherSettings reflects the audio state")
    func publisherSettingsReflectsAudioOff() {
        let sut = makeMockPublisher(publishAudio: false)

        let settings = sut.publisherSettings()

        #expect(settings.publishAudio == false)
    }

    @Test("Given publisher with publishVideo false, publisherSettings reflects the video state")
    func publisherSettingsReflectsVideoOff() {
        let sut = makeMockPublisher(publishVideo: false)

        let settings = sut.publisherSettings()

        #expect(settings.publishVideo == false)
    }

    @Test("Given advancedSettings, publisherSettings carries them over to the result")
    func publisherSettingsCarriesAdvancedSettings() {
        let advanced = PublisherAdvancedSettings(videoResolution: .high, maxAudioBitrate: 64_000)
        let sut = makeMockPublisher()

        let settings = sut.publisherSettings(username: "Bob", advancedSettings: advanced)

        #expect(settings.advancedSettings == advanced)
        #expect(settings.username == "Bob")
    }

    // MARK: - Helpers

    private func makeMockPublisher(
        publishAudio: Bool = true,
        publishVideo: Bool = true
    ) -> StubVERAPublisher {
        StubVERAPublisher(publishAudio: publishAudio, publishVideo: publishVideo)
    }
}

// MARK: - Stub

private final class StubVERAPublisher: VERAPublisher {
    var view: AnyView = AnyView(Color.clear)
    var publishAudio: Bool
    var publishVideo: Bool
    var cameraPosition: CameraPosition = .front
    var videoTransformers: [any VERATransformer] = []
    var audioTransformers: [any VERATransformer] = []
    var transformerFactory: any VERATransformerFactory = StubTransformerFactory()
    var audioLevelPublisher: AnyPublisher<Float, Never> {
        Just(0.0).eraseToAnyPublisher()
    }

    init(publishAudio: Bool = true, publishVideo: Bool = true) {
        self.publishAudio = publishAudio
        self.publishVideo = publishVideo
    }

    func switchCamera(to cameraDeviceID: String) {}
    func cleanUp() {}
    func addVideoTransformer(_ transformer: any VERATransformer) {}
    func setVideoTransformers(_ transformers: [any VERATransformer]) {}
    func removeTransformer(_ key: String) {}
    func addAudioTransformer(_ transformer: any VERATransformer) {}
    func setAudioTransformers(_ transformers: [any VERATransformer]) {}
    func removeAudioTransformer(_ key: String) {}
}

private final class StubTransformerFactory: VERATransformerFactory {
    func makeVideoTransformer(for key: String, params: String) throws -> any VERATransformer {
        fatalError("Not needed in tests")
    }

    func makeAudioTransformer(for key: String, params: String) throws -> any VERATransformer {
        fatalError("Not needed in tests")
    }
}
