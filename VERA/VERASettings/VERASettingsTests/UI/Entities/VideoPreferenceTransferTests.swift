//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("Persisted video preference value transfer")
struct VideoPreferenceTransferTests {

    @Test("Resolution cases retain persisted values and domain mapping after transfer")
    func resolutionsAcrossTasksAndActor() async throws {
        let received = try await transfer(SettingsVideoResolution.allCases, persistedValues: [0, 1, 2, 3])
        #expect(received.map(\.id) == [0, 1, 2, 3])
        #expect(received.map(\.vonageResolution) == [.low, .mediun, .high, .high1080p])
        #expect(received.map(\.displayName) == SettingsVideoResolution.allCases.map(\.displayName))
    }

    @Test("Frame-rate cases retain persisted values, labels and domain mapping after transfer")
    func frameRatesAcrossTasksAndActor() async throws {
        let received = try await transfer(SettingsVideoFrameRate.allCases, persistedValues: [1, 7, 15, 30])
        #expect(received.map(\.id) == [1, 7, 15, 30])
        #expect(received.map(\.vonageFrameRate) == [.rate1FPS, .rate7FPS, .rate15FPS, .rate30FPS])
        #expect(received.map(\.displayName) == ["1 FPS", "7 FPS", "15 FPS", "30 FPS"])
    }

    @Test("Bitrate presets retain persisted values and domain mapping after transfer")
    func bitratePresetsAcrossTasksAndActor() async throws {
        let received = try await transfer(SettingsVideoBitratePreset.allCases, persistedValues: [0, 1, 2, 3])
        #expect(received.map(\.id) == ["0", "1", "2", "3"])
        #expect(received.map(\.vonageBitratePreset) == [.default, .bwSaver, .extraBwSaver, .customBitrate])
        #expect(received.map(\.displayName) == SettingsVideoBitratePreset.allCases.map(\.displayName))
    }

    @Test("Degradation policies retain the negative sentinel and domain mapping after transfer")
    func degradationPreferencesAcrossTasksAndActor() async throws {
        let received = try await transfer(SettingsDegradationPreference.allCases, persistedValues: [-1, 0, 1, 2, 3])
        #expect(received.map(\.id) == ["-1", "0", "1", "2", "3"])
        #expect(
            received.map(\.vonageDegradationPreference)
                == [.notSet, .maintainFrameRateAndResolution, .maintainFrameRate, .maintainResolution, .balanced])
        #expect(received.map(\.displayName) == SettingsDegradationPreference.allCases.map(\.displayName))
    }

    private func transfer<Value: Sendable & Codable & RawRepresentable>(
        _ values: [Value], persistedValues: [Int]
    ) async throws -> [Value] where Value.RawValue == Int {
        #expect(values.map(\.rawValue) == persistedValues)
        let fixture = try JSONEncoder().encode(persistedValues)
        let decoded = try JSONDecoder().decode([Value].self, from: fixture)
        let transferred = await Task.detached { decoded }.value

        let selection = VideoPreferenceSelection<Value>()
        await selection.update(transferred)
        let received = await selection.values
        #expect(received.map(\.rawValue) == persistedValues)

        let encoded = try JSONEncoder().encode(received)
        #expect(try JSONDecoder().decode([Int].self, from: encoded) == persistedValues)
        return received
    }
}

private actor VideoPreferenceSelection<Value: Sendable> {
    private(set) var values: [Value] = []

    func update(_ selections: [Value]) {
        values = selections
    }
}
