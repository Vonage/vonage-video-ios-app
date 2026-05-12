//
//  Created by Vonage on 12/8/25.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import VERACore
@testable import VERAMeetingRoom

@Suite("Active speaker layout UI Tests")
@MainActor
struct ActiveSpeakerLayoutUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "ActiveSpeakerLayout"

    // MARK: - Core UI Tests

    @Test("Active Speaker Layout - Basic Layout")
    func basicLayout() throws {
        let sut = makeSUT()

        snapshot(sut, named: "Default")
    }

    @Test(
        "Active Speaker Layout - Size Classes",
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
        "Active Speaker Layout - Color Schemes",
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
        "Active Speaker Layout - Accessibility",
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

    private func makeSUT() -> ActiveSpeakerLayout {
        return ActiveSpeakerLayout(
            participants: PreviewData.uiManyParticipants,
            activeSpeakerId: PreviewData.arthurDent.id)
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}

// MARK: - Screen Share Layout Tests

@Suite("Screen Share Layout UI Tests")
@MainActor
struct ScreenShareLayoutUITests {

    private let isRecording = false
    private let snapshotPrefix = "ScreenShareLayout"

    @Test("Screen Share Layout - Screen share only")
    func screenShareOnly() throws {
        let sut = ActiveSpeakerLayout(
            participants: PreviewData.uiParticipantsWithScreenShare,
            activeSpeakerId: nil
        )

        snapshot(sut, named: "ScreenShareOnly")
    }

    @Test("Screen Share Layout - Screen share with pinned participant")
    func screenShareWithPinned() throws {
        let sut = ActiveSpeakerLayout(
            participants: PreviewData.uiParticipantsWithScreenShareAndPinned,
            activeSpeakerId: nil
        )

        snapshot(sut, named: "ScreenShareWithPinned")
    }

    @Test(
        "Screen Share Layout - Size classes",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPad", ViewImageConfig.iPadPro12_9),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
        ])
    func sizeClasses(deviceName: String, config: ViewImageConfig) throws {
        let sut = ActiveSpeakerLayout(
            participants: PreviewData.uiParticipantsWithScreenShare,
            activeSpeakerId: nil
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(deviceName)"
        )
    }

    @Test(
        "Screen Share Layout - Size classes with pinned participant",
        arguments: [
            ("iPhone", ViewImageConfig.iPhone13),
            ("iPad", ViewImageConfig.iPadPro12_9),
            ("iPhoneLandscape", ViewImageConfig.iPhone13(.landscape)),
        ])
    func sizeClassesWithPinned(deviceName: String, config: ViewImageConfig) throws {
        let sut = ActiveSpeakerLayout(
            participants: PreviewData.uiParticipantsWithScreenShareAndPinned,
            activeSpeakerId: nil
        )

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: config)),
            named: deviceName,
            record: isRecording,
            testName: "\(snapshotPrefix)_Pinned_\(deviceName)"
        )
    }

    // MARK: - Test Helpers

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}

@Suite("Active Speaker Layout Components")
@MainActor
struct ActiveSpeakerLayoutTests {

    private let isRecording = false
    private let snapshotPrefix = "ActiveSpeakerLayout"

    @Test(
        "Layout Components",
        arguments: [
            ("Horizontal", 800, 400),
            ("Vertical", 375, 600),
        ])
    func layoutComponents(layoutName: String, width: CGFloat, height: CGFloat) throws {
        let view: AnyView

        switch layoutName {
        case "Horizontal":
            view = AnyView(
                HorizontalActiveSpeakerLayoutView(
                    participants: PreviewData.uiManyParticipants,
                    activeSpeakerId: PreviewData.arthurDent.id)
            )
        case "Vertical":
            view = AnyView(
                VerticalActiveSpeakerLayoutView(
                    participants: PreviewData.uiManyParticipants,
                    activeSpeakerId: PreviewData.arthurDent.id)
            )
        default:
            return
        }

        let framedView =
            view
            .frame(width: width, height: height)
            .background(Color(.systemBackground))

        assertSnapshot(
            of: framedView,
            as: .image(precision: 0.99, layout: .fixed(width: width, height: height)),
            named: layoutName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(layoutName)"
        )
    }
}
