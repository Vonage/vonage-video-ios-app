//
//  Created by Vonage on 16/7/25.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERATestHelpers

@testable import VERACore

@Suite("Waiting room View UI Tests")
@MainActor
class WaitingRoomViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "WaitingRoom"
    private var publisher: VERAPublisher?

    init() {
        publisher = MockVERAPublisher()
    }

    @MainActor
    deinit {
        publisher = nil
    }

    // MARK: - Core UI Tests

    @Test("Waiting room View - Basic Layout")
    func basicLayout() throws {
        let sut = makeSUT()

        snapshot(sut, named: "Default")
    }

    @Test(
        "Waiting room View - Size Classes",
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
        "Waiting room View - Color Schemes",
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
        "Waiting room View - Accessibility",
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

    private func makeSUT() -> WaitingRoomView {
        WaitingRoomView(
            state: makeWaitingRoomState(publisher: publisher),
            userName: .constant("Trillian"),
            onJoinRoom: {},
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )
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

// MARK: - Component Tests

@Suite("Waiting room Components")
@MainActor
class WaitingRoomComponentTests {

    private let isRecording = false
    private let snapshotPrefix = "WaitingRoom"
    private var publisher: VERAPublisher?

    init() {
        publisher = MockVERAPublisher()
    }

    @MainActor
    deinit {
        publisher = nil
    }

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
                HorizontalWaitingRoomContentView(
                    state: makeWaitingRoomState(publisher: publisher),
                    userName: .constant("Trillian"),
                    onJoinRoom: {},
                    onMicrophoneToggle: {},
                    onCameraToggle: {})
            )
        case "Vertical":
            view = AnyView(
                VerticalWaitingRoomContentView(
                    state: makeWaitingRoomState(publisher: publisher),
                    userName: .constant("Trillian"),
                    onJoinRoom: {},
                    onMicrophoneToggle: {},
                    onCameraToggle: {})
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
