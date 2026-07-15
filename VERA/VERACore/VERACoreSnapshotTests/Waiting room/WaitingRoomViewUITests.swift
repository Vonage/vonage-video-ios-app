//
//  Created by Vonage on 16/7/25.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI
import VERADomain
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

    @Test("Waiting room View - With Audio Output Test Button")
    func withAudioOutputTestButton() throws {
        let sut = makeSUT(includeAudioOutputTestButton: true)

        snapshot(sut, named: "WithAudioOutputButton")
    }

    @Test(
        "Waiting room View - Size Classes",
        arguments: [
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
        "Waiting room View - With Audio Output Button Color Schemes",
        arguments: [("Light", ColorScheme.light), ("Dark", ColorScheme.dark)])
    func audioOutputButtonColorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(includeAudioOutputTestButton: true)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_AudioOutput_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(includeAudioOutputTestButton: Bool = false) -> WaitingRoomView {
        let audioOutputButton: ViewHolder? =
            includeAudioOutputTestButton
            ? ViewHolder(id: "audioTest") {
                Button(action: {}) {
                    Label {
                        Text("Audio")
                    } icon: {
                        VERACommonUIAsset.Images.audioMidLine.swiftUIImage
                    }
                }
            }
            : nil

        return WaitingRoomView(
            state: makeWaitingRoomState(
                publisher: publisher,
                allowAudioOutputTest: includeAudioOutputTestButton
            ),
            userName: .constant("Trillian"),
            toolbarButtons: .constant([]),
            extraTrailingButtons: .constant([]),
            audioOutputTestButton: .constant(audioOutputButton),
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
