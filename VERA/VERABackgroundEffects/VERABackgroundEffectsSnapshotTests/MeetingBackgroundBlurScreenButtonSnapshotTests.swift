//
//  Created by Vonage on 25/05/2026.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERABackgroundEffects

@Suite("MeetingBackgroundBlurScreenButton UI Tests")
@MainActor
struct MeetingBackgroundBlurScreenButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "MeetingBackgroundBlurScreenButton"

    // MARK: - Core UI Tests

    @Test(
        "MeetingBackgroundBlurScreenButton - Color Schemes and Video Effects",
        arguments: [
            ("Light-none", ColorScheme.light, VideoEffect.none),
            ("Dark-none", ColorScheme.dark, VideoEffect.none),
        ])
    func colorSchemesAndVideoEffects(
        schemeName: String,
        scheme: ColorScheme,
        effect: VideoEffect
    ) throws {
        let viewModel = makeMockViewModel(effect: effect)
        let sut = MeetingBackgroundBlurScreenButton(viewModel: viewModel)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .fixed(width: 80, height: 80)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Test Helpers

    private func makeMockViewModel(effect: VideoEffect) -> BackgroundBlurButtonViewModel {
        let viewModel = BackgroundBlurButtonViewModel {
            MockVERAPublisher()
        }
        viewModel.currentVideoEffect = effect
        return viewModel
    }
}
