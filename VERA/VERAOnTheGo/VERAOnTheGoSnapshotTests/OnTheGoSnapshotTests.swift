//
//  Created by Vonage on 17/10/26.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERACommonUI

@testable import VERAOnTheGo

@Suite("OnTheGo Snapshot Tests")
@MainActor
struct OnTheGoSnapshotTests {

    private let isRecording = false  // Set to true to record new snapshots
    private let snapshotPrefix = "OnTheGo"

    // MARK: - SUT factories

    private func makeViewModel(
        isMicEnabled: Bool = true,
        withScreenShare: Bool = false
    ) -> OnTheGoViewModel {
        let defaults = UserDefaults(suiteName: "VERAOnTheGoSnapshotTests") ?? .standard
        let viewModel = OnTheGoViewModel(
            configuration: .init(),
            preferences: UserDefaultsOnTheGoPreferencesRepository(userDefaults: defaults),
            motionProvider: nil,
            actions: OnTheGoCallActions(toggleMic: {}, toggleCamera: {}, endCall: {})
        )
        viewModel.update(
            snapshot: OnTheGoCallSnapshot(
                isConnected: true,
                isMicEnabled: isMicEnabled,
                isCameraEnabled: false,
                participantCount: 5,
                activeSpeakerName: isMicEnabled ? "Alice" : nil,
                screenShareParticipant: withScreenShare
                    ? .init(id: "share", name: "Screen share", isScreenshare: true)
                    : nil
            )
        )
        viewModel.enterManually()
        return viewModel
    }

    // MARK: - OnTheGoView

    @Test("OnTheGoView - mic on, dark")
    func micOnDark() throws {
        let sut = OnTheGoView(viewModel: makeViewModel())
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            record: isRecording,
            testName: "\(snapshotPrefix)_micOn-Dark"
        )
    }

    @Test("OnTheGoView - muted with screen share, dark")
    func mutedWithScreenShareDark() throws {
        let sut = OnTheGoView(viewModel: makeViewModel(isMicEnabled: false, withScreenShare: true))
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            record: isRecording,
            testName: "\(snapshotPrefix)_mutedShare-Dark"
        )
    }

    @Test("OnTheGoView - mic on, light")
    func micOnLight() throws {
        let sut = OnTheGoView(viewModel: makeViewModel())
            .environment(\.colorScheme, .light)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            record: isRecording,
            testName: "\(snapshotPrefix)_micOn-Light"
        )
    }

    @Test("OnTheGoView - iPhone SE size, muted with screen share")
    func seSizeMutedShare() throws {
        let sut = OnTheGoView(viewModel: makeViewModel(isMicEnabled: false, withScreenShare: true))
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhoneSe)),
            record: isRecording,
            testName: "\(snapshotPrefix)_SE-mutedShare"
        )
    }

    @Test("OnTheGoView - landscape, mic on")
    func landscape() throws {
        let sut = OnTheGoView(viewModel: makeViewModel(withScreenShare: true))
            .environment(\.colorScheme, .dark)
            .environment(\.verticalSizeClass, .compact)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13(.landscape))),
            record: isRecording,
            testName: "\(snapshotPrefix)_landscape"
        )
    }

    // MARK: - Suggestion banner

    @Test("OnTheGoSuggestionBanner - dark")
    func bannerDark() throws {
        let sut = OnTheGoSuggestionBanner(viewModel: makeViewModel())
            .frame(width: 360)
            .padding()
            .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            record: isRecording,
            testName: "\(snapshotPrefix)_banner-Dark"
        )
    }

    // MARK: - Settings row

    @Test("OnTheGoSettingsRow - light, motion permission denied")
    func settingsRowLightDenied() throws {
        let defaults = UserDefaults(suiteName: "VERAOnTheGoSnapshotTests") ?? .standard
        let sut = Form {
            OnTheGoSettingsRow(
                preferences: UserDefaultsOnTheGoPreferencesRepository(userDefaults: defaults),
                isMotionPermissionDenied: true
            )
        }
        .environment(\.colorScheme, .light)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            record: isRecording,
            testName: "\(snapshotPrefix)_settingsRow-Light-denied"
        )
    }
}
