//
//  Created by Vonage on 15/4/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain

@testable import VERAMeetingRoom

@Suite("MeetingRoomView UI Tests")
@MainActor
struct MeetingRoomViewUITests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "MeetingRoomView"

    // MARK: - State Variant Tests

    @Test(
        "MeetingRoomView - State Variants",
        arguments: [
            "Archiving",
            "NoiseSuppression",
            "CameraDisabled",
            "AllIndicators",
        ])
    func stateVariants(variantName: String) throws {
        let sut: MeetingRoomView

        switch variantName {
        case "Archiving":
            sut = makeSUT(archivingState: .archiving("archive-1"))
        case "NoiseSuppression":
            sut = makeSUT(noiseSuppressionState: .enabled)
        case "CameraDisabled":
            sut = makeSUT(isCameraEnabled: false)
        case "AllIndicators":
            sut = makeSUT(
                archivingState: .archiving("archive-2"),
                noiseSuppressionState: .enabled
            )
        default:
            return
        }

        snapshot(sut, named: "State_\(variantName)")
    }

    // MARK: - Share URL Tests

    @Test(
        "MeetingRoomView - Share URL Visibility",
        arguments: [
            "WithShareURL",
            "WithoutShareURL",
        ])
    func shareURLVisibility(variantName: String) throws {
        let roomURL: URL? =
            variantName == "WithShareURL"
            ? URL(string: "https://video.vonage.com/heart-of-gold")
            : nil
        let sut = makeSUT(roomURL: roomURL)

        snapshot(sut, named: "ShareURL_\(variantName)")
    }

    // MARK: - Color Scheme Tests

    @Test(
        "MeetingRoomView - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(schemeName: String, scheme: ColorScheme) throws {
        let sut = makeSUT(
            archivingState: .archiving("archive-1"),
            noiseSuppressionState: .enabled
        )
        .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeSUT(
        roomURL: URL? = URL(string: "https://video.vonage.com/heart-of-gold"),
        isMicEnabled: Bool = true,
        isCameraEnabled: Bool = true,
        archivingState: ArchivingState = .idle,
        noiseSuppressionState: NoiseSuppressionState = .disabled
    ) -> MeetingRoomView {
        MeetingRoomView(
            state: MeetingRoomState(
                roomName: "heart-of-gold",
                roomURL: roomURL,
                isMicEnabled: isMicEnabled,
                isCameraEnabled: isCameraEnabled,
                participants: [],
                layout: .activeSpeaker,
                activeSpeakerId: nil,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                showParticipantList: true,
                callState: .connected,
                archivingState: archivingState,
                noiseSuppressionState: noiseSuppressionState
            ),
            actions: MeetingRoomActions()
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
