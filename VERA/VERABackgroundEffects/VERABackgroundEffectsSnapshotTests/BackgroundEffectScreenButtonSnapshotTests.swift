//
//  Created by Vonage on 25/05/2026.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERABackgroundEffects

@Suite("BackgroundEffectScreenButton UI Tests")
@MainActor
struct BackgroundEffectScreenButtonSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "BackgroundEffectScreenButton"

    // MARK: - Core UI Tests

    @Test(
        "BackgroundEffectScreenButton - Color Schemes and Video Effects",
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
        let sut = BackgroundEffectScreenButton(viewModel: viewModel)
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

    private func makeMockViewModel(effect: VideoEffect) -> VideoEffectsViewModel {
        let viewModel = VideoEffectsViewModel(
            getCurrentPublisher: { MockVERAPublisher() },
            getBackgroundsUseCase: GetBackgroundsUseCase(
                backgroundEffectsRepository: StubBackgroundEffectsRepository(),
                userBackgroundRepository: StubUserBackgroundRepository()
            ),
            addBackgroundUseCase: AddBackgroundUseCase(
                userBackgroundRepository: StubUserBackgroundRepository()
            ),
            deleteBackgroundUseCase: DeleteBackgroundUseCase(
                userBackgroundRepository: StubUserBackgroundRepository(),
                videoEffectRepository: StubVideoEffectRepository()
            ),
            videoEffectRepository: StubVideoEffectRepository(storedEffect: effect)
        )
        return viewModel
    }
}

// MARK: - Stubs

private final class StubBackgroundEffectsRepository: BackgroundEffectsRepository {
    func availableBackgrounds() throws -> [VideoBackgroundItem] { [] }
}

private final class StubUserBackgroundRepository: UserBackgroundRepository {
    static let maxUserBackgrounds = 10
    func savedBackgrounds() throws -> [VideoBackgroundItem] { [] }
    func save(_ imageData: Data) throws -> VideoBackgroundItem {
        VideoBackgroundItem(id: "stub", imagePath: "/tmp/stub.jpg", isUserUploaded: true)
    }
    func delete(_ id: String) throws {}
    var remainingSlots: Int { 10 }
}

private final class StubVideoEffectRepository: VideoEffectRepository {
    private let storedEffect: VideoEffect
    init(storedEffect: VideoEffect = .none) { self.storedEffect = storedEffect }
    func save(_ effect: VideoEffect) throws {}
    func load() -> VideoEffect { storedEffect }
}
