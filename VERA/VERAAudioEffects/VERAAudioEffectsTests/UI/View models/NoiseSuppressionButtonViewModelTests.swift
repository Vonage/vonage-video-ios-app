//
//  Created by Vonage on 12/3/26.
//

import Foundation
import SwiftUI
import Testing
import VERAAudioEffects
import VERADomain
import VERATestHelpers

@Suite("NoiseSuppressionButtonViewModel tests")
struct NoiseSuppressionButtonViewModelTests {

    @Test
    @MainActor
    func initialStateIsDisabled() async throws {
        let sut = makeSUT()

        #expect(sut.state == .disabled)
    }

    @Test
    @MainActor
    func onTapTogglesFromDisabledToEnabled() async throws {
        let sut = makeSUT()

        #expect(sut.state == .disabled)

        sut.onTap()

        #expect(sut.state == .enabled)
    }

    @Test
    @MainActor
    func onTapTogglesFromEnabledToDisabled() async throws {
        let sut = makeSUT()
        sut.state = .enabled

        sut.onTap()

        #expect(sut.state == .disabled)
    }

    @Test
    @MainActor
    func onTapCallsEnableUseCaseWhenEnabling() async throws {
        let spy = PublisherSpy()
        let enableUseCase = EnableUseCaseSpy()
        let sut = makeSUT(
            getCurrentPublisher: { spy },
            enableUseCase: enableUseCase
        )

        sut.onTap()
        await Task.yield()  // Allow async transformer update to complete

        #expect(enableUseCase.callCount == 1)
        #expect(enableUseCase.lastPublisher === spy)
    }

    @Test
    @MainActor
    func onTapCallsDisableUseCaseWhenDisabling() async throws {
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(disableUseCase: disableUseCase)
        sut.state = .enabled

        sut.onTap()
        await Task.yield()

        #expect(disableUseCase.callCount == 1)
    }

    @Test
    @MainActor
    func onTapAppliesCorrectStateToPublisher() async throws {
        let enableUseCase = EnableUseCaseSpy()
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(
            disableUseCase: disableUseCase,
            enableUseCase: enableUseCase
        )

        // Disabled -> Enabled
        sut.onTap()
        await Task.yield()
        #expect(enableUseCase.callCount == 1)
        #expect(disableUseCase.callCount == 0)

        // Enabled -> Disabled
        sut.onTap()
        await Task.yield()
        #expect(enableUseCase.callCount == 1)
        #expect(disableUseCase.callCount == 1)
    }

    @Test
    @MainActor
    func onTapHandlesPublisherErrorGracefully() async throws {
        let sut = makeSUT(
            getCurrentPublisher: {
                throw NSError(domain: "Test", code: -1)
            }
        )

        // Should not crash
        sut.onTap()

        // State should still change
        #expect(sut.state == .enabled)
    }

    @Test
    @MainActor
    func multipleTapsToggleBetweenStates() async throws {
        let enableUseCase = EnableUseCaseSpy()
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(
            disableUseCase: disableUseCase,
            enableUseCase: enableUseCase
        )

        #expect(enableUseCase.callCount == 0)
        #expect(sut.state == .disabled)

        sut.onTap()  // disabled -> enabled
        await Task.yield()
        #expect(sut.state == .enabled)
        #expect(enableUseCase.callCount == 1)

        sut.onTap()  // enabled -> disabled
        await Task.yield()
        #expect(sut.state == .disabled)
        #expect(disableUseCase.callCount == 1)

        sut.onTap()  // disabled -> enabled (cycle repeats)
        await Task.yield()
        #expect(sut.state == .enabled)
        #expect(enableUseCase.callCount == 2)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        getCurrentPublisher: @escaping () throws -> VERAPublisher = { PublisherSpy() },
        disableUseCase: DisableNoiseSuppresionUseCase = DisableUseCaseSpy(),
        enableUseCase: EnableNoiseSuppresionUseCase = EnableUseCaseSpy()
    ) -> NoiseSuppressionViewModel {
        NoiseSuppressionViewModel(
            getCurrentPublisher: getCurrentPublisher,
            disableNoiseSuppresionUseCase: disableUseCase,
            enableNoiseSuppresionUseCase: enableUseCase
        )
    }
}

// MARK: - Mocks

final class PublisherSpy: VERAPublisher {
    var audioTransformers: [any VERATransformer] = []
    var transformerFactory: any VERATransformerFactory
    var view: AnyView { AnyView(EmptyView()) }
    var videoTransformers: [any VERATransformer] = []
    var publishAudio: Bool = true
    var publishVideo: Bool = true
    var cameraPosition: CameraPosition = .front

    func addVideoTransformer(_ transformer: any VERATransformer) {}
    func setVideoTransformers(_ transformers: [any VERATransformer]) {}
    func removeTransformer(_ key: String) {}
    func addAudioTransformer(_ transformer: any VERATransformer) {}
    func setAudioTransformers(_ transformers: [any VERATransformer]) {}
    func removeAudioTransformer(_ key: String) {}
    func switchCamera(to cameraDeviceID: String) {}
    func cleanUp() {}

    init(transformerFactory: VERATransformerFactory = MockTransformerFactory()) {
        self.transformerFactory = transformerFactory
    }
}

final class EnableUseCaseSpy: EnableNoiseSuppresionUseCase {
    var callCount = 0
    var lastPublisher: VERAPublisher?

    func callAsFunction(publisher: VERAPublisher) {
        callCount += 1
        lastPublisher = publisher
    }
}

final class DisableUseCaseSpy: DisableNoiseSuppresionUseCase {
    var callCount = 0

    func callAsFunction() {
        callCount += 1
    }
}
