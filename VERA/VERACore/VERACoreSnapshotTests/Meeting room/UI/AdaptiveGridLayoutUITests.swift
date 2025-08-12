//
//  Created by Vonage on 12/8/25.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERACore

@Suite("AdaptiveGrid layout UI Tests")
@MainActor
struct AdaptiveGridLayoutUITests {

    // MARK: - Test Configuration

    private let isRecording = true  // Set to true to record new snapshots
    private let snapshotPrefix = "AdaptiveGridLayout"

    // MARK: - Core UI Tests

    @Test(
        "Adaptive Grid Layout - No participants",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13)
        ])
    func emptyLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: [])

        snapshot(sut, named: "\(deviceName)_Empty", config: config)
    }

    @Test(
        "Adaptive Grid Layout - One participant layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func oneParticipantLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: [PreviewData.arthurDent])

        snapshot(sut, named: "\(deviceName)_OneParticipant", config: config)
    }

    @Test(
        "Adaptive Grid Layout - Two participants layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func twoParticipantsLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: [
            PreviewData.arthurDent, PreviewData.trillian,
        ])

        snapshot(sut, named: "\(deviceName)_TwoParticipants", config: config)
    }

    @Test(
        "Adaptive Grid Layout - Three participants layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func threeParticipantsLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: [
            PreviewData.arthurDent, PreviewData.trillian,
            PreviewData.marvin,
        ])

        snapshot(sut, named: "\(deviceName)_ThreeParticipants", config: config)
    }

    @Test(
        "Adaptive Grid Layout - Four participants layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func fourParticipantsLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: [
            PreviewData.arthurDent, PreviewData.trillian,
            PreviewData.marvin, PreviewData.zaphodBeeblebrox,
        ])

        snapshot(sut, named: "\(deviceName)_FourParticipants", config: config)
    }

    @Test(
        "Adaptive Grid Layout - Many participants layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func manyParticipantsLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: PreviewData.manyParticipants)

        snapshot(sut, named: "\(deviceName)_ManyParticipants", config: config)
    }

    @Test(
        "Adaptive Grid Layout - twenty participants layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func twentyParticipantsLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: createParticipants(count: 20))

        snapshot(sut, named: "\(deviceName)_TwentyParticipants", config: config)
    }

    @Test(
        "Adaptive Grid Layout - thirty participants layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func thirtyParticipantsLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: createParticipants(count: 30))

        snapshot(sut, named: "\(deviceName)_ThirtyParticipants", config: config)
    }

    @Test(
        "Adaptive Grid Layout - fifty participants layout",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
            ("iPad", ViewImageConfig.iPadPro11),
        ])
    func fiftyParticipantsLayout(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT(participants: createParticipants(count: 50))

        snapshot(sut, named: "\(deviceName)_FiftyParticipants", config: config)
    }

    @Test(
        "Adaptive Grid Layout - Size Classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPad", ViewImageConfig.iPadPro12_9),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
        ])
    func sizeClasses(deviceName: String, config: ViewImageConfig) throws {
        let sut = makeSUT()

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "Adaptive Grid Layout - Color Schemes",
        arguments: [("Light", ColorScheme.light), ("Dark", ColorScheme.dark)])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT()
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    @Test(
        "Adaptive Grid Layout - Accessibility",
        arguments: [
            ("SmallText", ContentSizeCategory.extraSmall),
            ("LargeText", ContentSizeCategory.accessibilityExtraExtraExtraLarge),
        ])
    func accessibility(textName: String, textSize: ContentSizeCategory) throws {
        let sut = makeSUT()
            .environment(\.sizeCategory, textSize)

        snapshot(sut, named: textName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        participants: [Participant] = PreviewData.manyParticipants
    ) -> AdaptiveGridLayout {
        return AdaptiveGridLayout(
            participants: participants,
            activeSpeakerId: PreviewData.marvin.id)
    }

    private func snapshot(
        _ view: some View,
        named: String,
        config: ViewImageConfig = .iPhone13,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }

    func createParticipants(count: Int) -> [Participant] {
        var participants: [Participant] = []
        for index in 1...count {
            participants.append(
                Participant(
                    id: "participant_\(index)",
                    name: "User \(index)", isMicEnabled: index % 3 != 0,
                    isCameraEnabled: index % 4 != 0,
                    videoDimensions: .init(width: 640, height: 480),
                    isRemote: true,
                    creationTime: Date().addingTimeInterval(TimeInterval(index)),
                    audioLevel: 0.0,
                    isScreenshare: false,
                    isPinned: false,
                    viewBuilder: { AnyView(Color.blue) })
            )
        }
        return participants
    }
}
