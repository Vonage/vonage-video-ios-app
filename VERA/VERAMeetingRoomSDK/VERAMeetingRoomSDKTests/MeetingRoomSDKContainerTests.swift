//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomSDKContainer tests")
struct MeetingRoomSDKContainerTests {

    private static let testBaseURL = URL(string: "https://api.example.com")!

    @Test("Container correctly reports feature enabled status")
    func featureEnabledStatus() {
        let container = makeContainer(enabledFeatures: [.chat, .captions])
        #expect(container.isFeatureEnabled(.chat))
        #expect(container.isFeatureEnabled(.captions))
        #expect(!container.isFeatureEnabled(.archiving))
        #expect(!container.isFeatureEnabled(.reactions))
        #expect(!container.isFeatureEnabled(.settings))
        #expect(!container.isFeatureEnabled(.screenShare))
        #expect(!container.isFeatureEnabled(.backgroundEffects))
        #expect(!container.isFeatureEnabled(.audioEffects))
    }

    @Test("Container with no features still creates core dependencies")
    func containerWithNoFeatures() {
        let container = makeContainer(enabledFeatures: [])
        #expect(container.baseURL == Self.testBaseURL)
        #expect(!container.isFeatureEnabled(.chat))
    }

    @Test("Container uses null captions data source when captions disabled")
    func nullCaptionsWhenDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let dataSource = container.captionsStatusDataSource
        #expect(dataSource is NullCaptionsStatusDataSource)
    }

    @Test("Container uses real captions data source when captions enabled")
    func realCaptionsWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.captions])
        let dataSource = container.captionsStatusDataSource
        #expect(!(dataSource is NullCaptionsStatusDataSource))
    }

    @Test("Container uses null noise suppression data source when audio effects disabled")
    func nullNoiseSuppressionWhenDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let dataSource = container.noiseSuppressionStatusDataSource
        #expect(dataSource is NullNoiseSuppressionStatusDataSource)
    }

    @Test("Container uses real noise suppression data source when audio effects enabled")
    func realNoiseSuppressionWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.audioEffects])
        let dataSource = container.noiseSuppressionStatusDataSource
        #expect(!(dataSource is NullNoiseSuppressionStatusDataSource))
    }

    @Test("Plugin registry includes CallKit plugin when enabled")
    func pluginRegistryIncludesCallKitWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.callKit])
        let plugins = container.pluginRegistry.plugins
        #expect(plugins.contains { $0.pluginIdentifier == "VonageCallKitPlugin" })
    }

    @Test("Plugin registry includes chat plugin when enabled")
    func pluginRegistryIncludesChatWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.chat])
        let plugins = container.pluginRegistry.plugins
        #expect(plugins.contains { $0.pluginIdentifier == "VonageChatPlugin" })
    }

    @Test("Plugin registry excludes chat plugin when disabled")
    func pluginRegistryExcludesChatWhenDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let plugins = container.pluginRegistry.plugins
        #expect(!plugins.contains { $0.pluginIdentifier == "VonageChatPlugin" })
    }

    @Test("Plugin registry has no duplicates")
    func pluginRegistryNoDuplicates() {
        let container = makeContainer(enabledFeatures: Set(MeetingRoomFeature.allCases))
        let plugins = container.pluginRegistry.plugins
        let identifiers = plugins.map(\.pluginIdentifier)
        let uniqueIdentifiers = Set(identifiers)
        #expect(identifiers.count == uniqueIdentifiers.count)
    }

    @Test("Container stores enabled features")
    func containerStoresEnabledFeatures() {
        let features: Set<MeetingRoomFeature> = [.chat, .archiving, .settings]
        let container = makeContainer(enabledFeatures: features)
        #expect(container.enabledFeatures == features)
    }

    @Test("Container stores configuration")
    func containerStoresConfiguration() {
        let config = MeetingRoomConfiguration(
            allowMicrophoneControl: false,
            allowCameraControl: true,
            showParticipantList: false
        )
        let container = MeetingRoomSDKContainer(
            baseURL: Self.testBaseURL,
            enabledFeatures: [],
            configuration: config,
            appGroupIdentifier: nil,
            broadcastExtensionBundleId: nil
        )
        #expect(container.configuration == config)
    }

    // MARK: - Helpers

    private func makeContainer(
        enabledFeatures: Set<MeetingRoomFeature>
    ) -> MeetingRoomSDKContainer {
        MeetingRoomSDKContainer(
            baseURL: Self.testBaseURL,
            enabledFeatures: enabledFeatures,
            configuration: MeetingRoomConfiguration(),
            appGroupIdentifier: nil,
            broadcastExtensionBundleId: nil
        )
    }
}
