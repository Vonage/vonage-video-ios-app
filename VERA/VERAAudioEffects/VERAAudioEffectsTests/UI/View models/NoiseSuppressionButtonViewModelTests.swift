//
//  Created by Vonage on 12/3/26.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERAAudioEffects
import VERADomain
import VERATestHelpers

@Suite("NoiseSuppressionButtonViewModel tests")
@MainActor
struct NoiseSuppressionButtonViewModelTests {

    @Test
    func initialStateIsDisabled() async throws {
        let sut = makeSUT()

        #expect(sut.state == .disabled)
    }

    @Test
    func onTapTogglesFromDisabledToEnabled() async throws {
        let sut = makeSUT()

        #expect(sut.state == .disabled)

        sut.onTap()

        #expect(sut.state == .enabled)
    }

    @Test
    func onTapTogglesFromEnabledToDisabled() async throws {
        let sut = makeSUT()
        sut.state = .enabled

        sut.onTap()

        #expect(sut.state == .disabled)
    }

    @Test
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
    func onTapCallsDisableUseCaseWhenDisabling() async throws {
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(disableUseCase: disableUseCase)
        sut.state = .enabled

        sut.onTap()
        await Task.yield()

        #expect(disableUseCase.callCount == 1)
    }

    @Test
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

    // MARK: - updateState(to:) Tests

    @Test
    func updateStateSetsStateToEnabled() {
        let sut = makeSUT()

        sut.updateState(to: .enabled)

        #expect(sut.state == .enabled)
    }

    @Test
    func updateStateSetsStateToDisabled() {
        let sut = makeSUT()
        sut.state = .enabled

        sut.updateState(to: .disabled)

        #expect(sut.state == .disabled)
    }

    @Test
    func updateStateToEnabledCallsEnableUseCase() async {
        let spy = PublisherSpy()
        let enableUseCase = EnableUseCaseSpy()
        let sut = makeSUT(getCurrentPublisher: { spy }, enableUseCase: enableUseCase)

        sut.updateState(to: .enabled)
        await Task.yield()

        #expect(enableUseCase.callCount == 1)
        #expect(enableUseCase.lastPublisher === spy)
    }

    @Test
    func updateStateToDisabledCallsDisableUseCase() async {
        let spy = PublisherSpy()
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(getCurrentPublisher: { spy }, disableUseCase: disableUseCase)

        sut.updateState(to: .disabled)
        await Task.yield()

        #expect(disableUseCase.callCount == 1)
    }

    @Test
    func updateStateToEnabledDoesNotCallDisableUseCase() async {
        let enableUseCase = EnableUseCaseSpy()
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(disableUseCase: disableUseCase, enableUseCase: enableUseCase)

        sut.updateState(to: .enabled)
        await Task.yield()

        #expect(enableUseCase.callCount == 1)
        #expect(disableUseCase.callCount == 0)
    }

    @Test
    func updateStateToDisabledDoesNotCallEnableUseCase() async {
        let enableUseCase = EnableUseCaseSpy()
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(disableUseCase: disableUseCase, enableUseCase: enableUseCase)

        sut.updateState(to: .disabled)
        await Task.yield()

        #expect(enableUseCase.callCount == 0)
        #expect(disableUseCase.callCount == 1)
    }

    @Test
    func updateStateHandlesPublisherErrorGracefully() {
        let sut = makeSUT(getCurrentPublisher: { throw NSError(domain: "Test", code: -1) })

        // Should not crash
        sut.updateState(to: .enabled)

        // State should still be updated
        #expect(sut.state == .enabled)
    }

    @Test
    func updateStateOverridesPreviousState() async {
        let sut = makeSUT()

        sut.updateState(to: .enabled)
        #expect(sut.state == .enabled)

        sut.updateState(to: .disabled)
        #expect(sut.state == .disabled)

        sut.updateState(to: .enabled)
        #expect(sut.state == .enabled)
    }

    @Test
    func updateStateIsIndependentFromOnTapToggle() async {
        let enableUseCase = EnableUseCaseSpy()
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(disableUseCase: disableUseCase, enableUseCase: enableUseCase)

        // Advance via onTap
        sut.onTap()  // disabled -> enabled
        await Task.yield()
        #expect(sut.state == .enabled)

        // updateState should set directly regardless of toggle cycle
        sut.updateState(to: .disabled)
        #expect(sut.state == .disabled)

        // onTap should now toggle from .disabled
        sut.onTap()
        await Task.yield()
        #expect(sut.state == .enabled)
    }

    @Test
    func bottomItemPresentableExposesMetadataAndAction() async {
        let enableUseCase = EnableUseCaseSpy()
        let disableUseCase = DisableUseCaseSpy()
        let sut = makeSUT(disableUseCase: disableUseCase, enableUseCase: enableUseCase)

        #expect(sut.id == "noise-suppression-button")
        #expect(sut.label == String(localized: "Noise Suppression", bundle: .veraAudioEffects))
        #expect(sut.accessibilityIdentifier == nil)
        #expect(sut.isActive == false)
        #expect(sut.accessory == nil)

        sut.performAction()
        await Task.yield()

        #expect(sut.isActive)
        #expect(enableUseCase.callCount == 1)

        sut.performAction()
        await Task.yield()

        #expect(sut.isActive == false)
        #expect(disableUseCase.callCount == 1)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        getCurrentPublisher: @escaping () throws -> VERAPublisher = { PublisherSpy() },
        disableUseCase: DisableNoiseSuppressionUseCase = DisableUseCaseSpy(),
        enableUseCase: EnableNoiseSuppressionUseCase = EnableUseCaseSpy()
    ) -> NoiseSuppressionViewModel {
        NoiseSuppressionViewModel(
            getCurrentPublisher: getCurrentPublisher,
            disableNoiseSuppressionUseCase: disableUseCase,
            enableNoiseSuppressionUseCase: enableUseCase
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
    var audioLevelPublisher: AnyPublisher<Float, Never> = CurrentValueSubject(0).eraseToAnyPublisher()

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

final class EnableUseCaseSpy: EnableNoiseSuppressionUseCase {
    var callCount = 0
    var lastPublisher: VERAPublisher?

    func callAsFunction(publisher: VERAPublisher) {
        callCount += 1
        lastPublisher = publisher
    }
}

final class DisableUseCaseSpy: DisableNoiseSuppressionUseCase {
    var callCount = 0

    func callAsFunction(publisher: VERAPublisher) {
        callCount += 1
    }
}
