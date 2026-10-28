//
//  Created by Vonage on 16/10/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain

@testable import VERAMeetingRoom

@Suite("ParticipantVideoCard UI Tests")
@MainActor
struct ParticipantVideoCardUITests {

    // MARK: - Test Configuration

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "ParticipantVideoCard"

    // MARK: - Mic indicator

    @Test(
        "ParticipantVideoCard - Mic indicator matches VERA Web for local and remote tiles",
        arguments: [
            ("LocalMuted_CameraOn", false, false, true),
            ("LocalMuted_CameraOff", false, false, false),
            ("LocalUnmuted_CameraOn", false, true, true),
            ("RemoteMuted_CameraOn", true, false, true),
        ])
    func micIndicator(name: String, isRemote: Bool, isMicEnabled: Bool, isCameraEnabled: Bool) {
        let sut = makeSUT(isRemote: isRemote, isMicEnabled: isMicEnabled, isCameraEnabled: isCameraEnabled)

        snapshot(sut, named: name)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        isRemote: Bool,
        isMicEnabled: Bool,
        isCameraEnabled: Bool
    ) -> some View {
        ParticipantVideoCard(
            participant: UIParticipant(
                participant: Participant(
                    id: "arthur",
                    name: "Arthur Dent",
                    isMicEnabled: isMicEnabled,
                    isCameraEnabled: isCameraEnabled,
                    videoDimensions: .init(width: 640, height: 480),
                    isRemote: isRemote,
                    creationTime: Date(timeIntervalSince1970: 0),
                    isScreenshare: false,
                    audioLevel: 0.5,
                    view: AnyView(Color.blue))),
            activeSpeakerId: nil
        )
        .frame(width: 320, height: 240)
    }

    private func snapshot(
        _ view: some View,
        named: String,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image(precision: 0.99, layout: .fixed(width: 320, height: 240)),
            named: named,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(named)",
            line: line,
            column: column
        )
    }
}
