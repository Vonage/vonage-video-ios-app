//
//  Created by Vonage on 01/06/2026.
//

import SnapshotTesting
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers

@testable import VERABackgroundEffects

@Suite("VideoEffectsSheet Snapshot Tests")
@MainActor
struct VideoEffectsSheetSnapshotTests {

    // MARK: - Test Configuration

    private let isRecording = false
    private let snapshotPrefix = "VideoEffectsSheet"

    // MARK: - Color Scheme Tests

    @Test(
        "VideoEffectsSheet - Color Schemes",
        arguments: [
            ("Light", ColorScheme.light),
            ("Dark", ColorScheme.dark),
        ])
    func colorSchemes(
        schemeName: String,
        scheme: ColorScheme
    ) throws {
        let viewModel = makeMockViewModel()
        viewModel.loadBackgrounds()
        let sut = VideoEffectsSheet(viewModel: viewModel)
            .environment(\.colorScheme, scheme)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: schemeName,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(schemeName)"
        )
    }

    // MARK: - Effect Selection Tests

    @Test(
        "VideoEffectsSheet - Selected Effects",
        arguments: [
            ("none-selected", VideoEffect.none),
            ("blur-low-selected", VideoEffect.blurLow),
            ("blur-high-selected", VideoEffect.blurHigh),
        ])
    func selectedEffects(
        variant: String,
        effect: VideoEffect
    ) throws {
        let viewModel = makeMockViewModel(effect: effect)
        viewModel.loadBackgrounds()
        let sut = VideoEffectsSheet(viewModel: viewModel)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: variant,
            record: isRecording,
            testName: "\(snapshotPrefix)_\(variant)"
        )
    }

    // MARK: - Backgrounds Grid Tests

    @Test("VideoEffectsSheet - With user backgrounds")
    func withBackgrounds() throws {
        let backgrounds = (0..<4).map {
            VideoBackgroundItem(id: "bg-\($0)", imagePath: "/tmp/bg\($0).jpg", isUserUploaded: $0 > 1)
        }
        let viewModel = makeMockViewModel(backgrounds: backgrounds, remainingSlots: 6)
        let sut = VideoEffectsSheet(viewModel: viewModel)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: "with-backgrounds",
            record: isRecording,
            testName: "\(snapshotPrefix)_with-backgrounds"
        )
    }

    @Test("VideoEffectsSheet - Max backgrounds reached")
    func maxBackgroundsReached() throws {
        let backgrounds = (0..<10).map {
            VideoBackgroundItem(id: "bg-\($0)", imagePath: "/tmp/bg\($0).jpg", isUserUploaded: $0 > 1)
        }
        let viewModel = makeMockViewModel(backgrounds: backgrounds, remainingSlots: 0)
        let sut = VideoEffectsSheet(viewModel: viewModel)

        assertSnapshot(
            of: sut,
            as: .image(precision: 0.99, layout: .device(config: .iPhone13)),
            named: "max-backgrounds",
            record: isRecording,
            testName: "\(snapshotPrefix)_max-backgrounds"
        )
    }

    // MARK: - Test Helpers

    private func makeMockViewModel(
        effect: VideoEffect = .none,
        backgrounds: [VideoBackgroundItem] = [],
        remainingSlots: Int = 10
    ) -> VideoEffectsViewModel {
        let repository = StubBackgroundEffectsRepository(backgrounds: backgrounds)
        let userRepo = StubUserBackgroundRepository(remainingSlots: remainingSlots)

        let viewModel = VideoEffectsViewModel(
            getCurrentPublisher: { MockVERAPublisher() },
            getBackgroundsUseCase: GetBackgroundsUseCase(
                backgroundEffectsRepository: repository,
                userBackgroundRepository: userRepo
            ),
            addBackgroundUseCase: AddBackgroundUseCase(
                userBackgroundRepository: userRepo
            ),
            deleteBackgroundUseCase: DeleteBackgroundUseCase(
                userBackgroundRepository: userRepo,
                videoEffectRepository: StubVideoEffectRepository(storedEffect: effect)
            ),
            videoEffectRepository: StubVideoEffectRepository(storedEffect: effect)
        )

        if !backgrounds.isEmpty {
            viewModel.backgrounds = backgrounds
            viewModel.remainingSlots = remainingSlots
        }

        return viewModel
    }
}

// MARK: - Stubs

private final class StubBackgroundEffectsRepository: BackgroundEffectsRepository {
    private let backgrounds: [VideoBackgroundItem]
    init(backgrounds: [VideoBackgroundItem] = []) { self.backgrounds = backgrounds }
    func availableBackgrounds() throws -> [VideoBackgroundItem] { backgrounds }
}

private final class StubUserBackgroundRepository: UserBackgroundRepository {
    static let maxUserBackgrounds = 10
    let remainingSlots: Int
    init(remainingSlots: Int = 10) { self.remainingSlots = remainingSlots }
    func savedBackgrounds() throws -> [VideoBackgroundItem] { [] }
    func save(_ imageData: Data) throws -> VideoBackgroundItem {
        VideoBackgroundItem(id: "stub", imagePath: "/tmp/stub.jpg", isUserUploaded: true)
    }
    func delete(_ id: String) throws {}
}

private final class StubVideoEffectRepository: VideoEffectRepository {
    private let storedEffect: VideoEffect
    init(storedEffect: VideoEffect = .none) { self.storedEffect = storedEffect }
    func save(_ effect: VideoEffect) {}
    func load() -> VideoEffect { storedEffect }
}
