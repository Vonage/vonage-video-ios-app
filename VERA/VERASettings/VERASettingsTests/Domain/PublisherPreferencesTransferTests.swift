//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("Publisher preferences snapshot transfer")
struct PublisherPreferencesTransferTests {
    @Test("Default and fully customized preferences retain every field after task and actor transfer")
    func completeSnapshotsAcrossTasksAndActor() async throws {
        let snapshots: [PublisherSettingsPreferences] = [.default, customizedPreferences()]
        let storage = PublisherPreferenceStorage()

        for snapshot in snapshots {
            let encoded = try JSONEncoder().encode(snapshot)
            let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: encoded)
            let transferred = await transfer(decoded)
            await storage.update(transferred)
            let received = await storage.preferences
            #expect(received == snapshot)
            #expect(
                try JSONDecoder().decode(PublisherSettingsPreferences.self, from: JSONEncoder().encode(received))
                    == snapshot)
        }
    }

    @Test("Legacy persisted preferences retain migration defaults and write the current schema after transfer")
    func legacyPersistenceAcrossTasksAndActor() async throws {
        let fixtures: [(String, PublisherSettingsPreferences)] = [
            (
                #"{"videoResolution":2,"videoFrameRate":15,"preferredVideoCodec":2,"maxAudioBitrate":64000,"audioFallbackEnabled":false}"#,
                .init(
                    videoResolution: .high, videoFrameRate: .fps15,
                    codecPreference: .init(mode: .manual, orderedCodecs: [.h264]),
                    audioBitratePreference: .custom(64_000), maxVideoBitrate: 0,
                    publisherAudioFallbackEnabled: false, subscriberAudioFallbackEnabled: false,
                    statsOverlayEnabled: true
                )
            ),
            (
                #"{"videoResolution":1,"videoFrameRate":30,"audioFallbackEnabled":true}"#,
                .init(
                    videoResolution: .medium, maxVideoBitrate: 0,
                    publisherAudioFallbackEnabled: true, subscriberAudioFallbackEnabled: true,
                    statsOverlayEnabled: true
                )
            ),
        ]
        let storage = PublisherPreferenceStorage()
        for (json, expected) in fixtures {
            let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: Data(json.utf8))
            await storage.update(await transfer(decoded))
            let received = await storage.preferences
            #expect(received == expected)
            let encoded = try JSONEncoder().encode(received)
            let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            #expect(object["preferredVideoCodec"] == nil)
            #expect(object["maxAudioBitrate"] == nil)
            #expect(object["audioFallbackEnabled"] == nil)
            #expect(object.count == 22)
            #expect(object["transcriptionSummaryEnabled"] as? Bool == true)
            #expect(try JSONDecoder().decode(PublisherSettingsPreferences.self, from: encoded) == expected)
        }
    }

    @Test("Editing transferred preferences leaves the original, static default and actor snapshot unchanged")
    func snapshotsRemainIndependent() async {
        let original = customizedPreferences()
        let storage = PublisherPreferenceStorage()
        await storage.update(original)
        let edited = await Task.detached {
            var copy = original
            copy.codecPreference.orderedCodecs.reverse()
            copy.audioBitratePreference = .default
            copy.maxVideoBitrate = 0
            copy.statsOverlayEnabled.toggle()
            return copy
        }.value

        #expect(original == customizedPreferences())
        #expect(edited.codecPreference.orderedCodecs == [.vp8, .vp9, .h264])
        #expect(edited.audioBitratePreference == .default)
        #expect(edited.maxVideoBitrate == 0)
        #expect(edited.statsOverlayEnabled)
        #expect(await storage.preferences == original)
        var readCopy = await storage.preferences
        readCopy.codecPreference.orderedCodecs.removeAll()
        #expect(await storage.preferences == original)
        #expect(PublisherSettingsPreferences.default == PublisherSettingsPreferences())
    }

    private func transfer<Value: Sendable>(_ value: Value) async -> Value {
        await Task.detached { value }.value
    }

    private func customizedPreferences() -> PublisherSettingsPreferences {
        .init(
            videoResolution: .high1080p, videoFrameRate: .fps15,
            codecPreference: .init(mode: .manual, orderedCodecs: [.h264, .vp9, .vp8]),
            audioBitratePreference: .custom(64_000), videoBitratePreset: .custom,
            maxVideoBitrate: 2_000_000, publisherAudioFallbackEnabled: false,
            subscriberAudioFallbackEnabled: false, senderStatsEnabled: true,
            statsOverlayEnabled: false, degradationPreference: .balanced, opusDtxEnabled: false
        )
    }
}

private actor PublisherPreferenceStorage {
    private(set) var preferences = PublisherSettingsPreferences.default

    func update(_ value: PublisherSettingsPreferences) {
        preferences = value
    }
}
