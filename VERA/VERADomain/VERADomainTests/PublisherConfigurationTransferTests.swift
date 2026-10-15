import Testing
import VERADomain

@Suite("Publisher configuration transfer")
struct PublisherConfigurationTransferTests {
    @Test("Default settings and room requests retain defaults after transfer")
    func defaults() async {
        let request = NewRoomRequest(roomName: "")
        let transferred = await Task.detached { request }.value
        let stored = await ConfigurationStore().store(transferred)
        #expect(stored == request)
        #expect(stored.publisherSettings.username == "")
        #expect(stored.publisherSettings.publishAudio)
        #expect(stored.publisherSettings.publishVideo)
        #expect(stored.publisherSettings.scaleBehavior == .fill)
        #expect(stored.publisherSettings.advancedSettings == nil)
        #expect(stored.publisherSettings.initialVideoEffect == nil)
        #expect(stored.publisherSettings.noiseSuppressionState == nil)
    }

    @Test("Full configuration and optional effect states cross task and actor boundaries")
    func fullConfiguration() async {
        let advanced = PublisherAdvancedSettings(
            videoResolution: .high1080p, videoFrameRate: .rate15FPS,
            preferredVideoCodecs: .init(automatic: false, codecs: [.vp9, .h264, .vp8]),
            maxAudioBitrate: 64000, videoBitratePreset: .customBitrate, maxVideoBitrate: 500000,
            publisherAudioFallbackEnabled: true, subscriberAudioFallbackEnabled: false,
            degradationPreference: .balanced, opusDtxEnabled: true
        )
        let effects: [VideoEffect?] = [
            nil, VideoEffect.none, .blurLow, .blurHigh,
            .backgroundImage(id: "背景", imagePath: "/synthetic/背景.png"),
        ]
        let noiseStates: [NoiseSuppressionState?] = [nil, .idle, .enabled, .disabled]
        let store = ConfigurationStore()
        for scale in [VideoScaleBehavior.fill, .fit] {
            for effect in effects {
                for noise in noiseStates {
                    let settings = PublisherSettings(
                        username: "Zoë 📹", publishAudio: false, publishVideo: true,
                        scaleBehavior: scale, advancedSettings: advanced,
                        initialVideoEffect: effect, noiseSuppressionState: noise
                    )
                    let request = NewRoomRequest(roomName: "会議", publisherSettings: settings)
                    let transferred = await Task.detached { request }.value
                    let stored = await store.store(transferred)
                    #expect(stored == request)
                    #expect(stored.publisherSettings == settings)
                    #expect(Set([stored, request]).count == 1)
                }
            }
        }
    }

    @Test("Transferred settings can be changed without mutating the original value")
    func independentCopy() async {
        let original = PublisherSettings(username: "original")
        let modified = await Task.detached {
            original.username("changed").publishAudio(false).publishVideo(false)
                .scaleBehavior(.fit).advancedSettings(.init(maxAudioBitrate: 32000))
                .initialVideoEffect(.blurLow).noiseSuppressionState(.enabled)
        }.value
        #expect(original == PublisherSettings(username: "original"))
        #expect(modified.username == "changed")
        #expect(!modified.publishAudio)
        #expect(!modified.publishVideo)
        #expect(modified.scaleBehavior == .fit)
        #expect(modified.advancedSettings?.maxAudioBitrate == 32000)
        #expect(modified.initialVideoEffect == .blurLow)
        #expect(modified.noiseSuppressionState == .enabled)
        let scales = await Task.detached { [VideoScaleBehavior.fill, .fit] }.value
        #expect(scales.map(\.rawValue) == ["fill", "fit"])
    }
}

private actor ConfigurationStore {
    private var request = NewRoomRequest(roomName: "")

    func store(_ value: NewRoomRequest) -> NewRoomRequest {
        request = value
        return request
    }
}
