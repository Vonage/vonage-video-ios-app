//
//  Created by Vonage on 29/1/26.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERABackgroundEffects
import VERADomain
import VERATestHelpers

@Suite("BackgroundBlurButtonViewModel tests")
@MainActor
struct BackgroundBlurButtonViewModelTests {

    enum Error: Swift.Error {
        case nilValue
        case publisherError
        case blurError
    }

    @Test
    func initialVideoEffectIsNone() async throws {
        let sut = makeSUT()

        #expect(sut.currentVideoEffect == .none)
    }

    @Test
    func onTapCyclesFromNoneToBlurLow() async throws {
        let sut = makeSUT()

        #expect(sut.currentVideoEffect == .none)

        sut.onTap()

        #expect(sut.currentVideoEffect == .blurLow)
    }

    @Test
    func onTapCyclesFromBlurLowToBlurHigh() async throws {
        let sut = makeSUT()
        sut.currentVideoEffect = .blurLow

        sut.onTap()

        #expect(sut.currentVideoEffect == .blurHigh)
    }

    @Test
    func onTapCyclesFromBlurHighToNone() async throws {
        let sut = makeSUT()
        sut.currentVideoEffect = .blurHigh

        sut.onTap()

        #expect(sut.currentVideoEffect == .none)
    }

    @Test
    func onTapCyclesFromBackgroundImageToNone() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })
        sut.currentVideoEffect = .backgroundImage(id: "sample", imagePath: "/tmp/sample.png")

        sut.onTap()

        #expect(sut.currentVideoEffect == .none)
        #expect(spy.addVideoTransformerCallCount == 0)
        #expect(spy.removeTransformerCallCount == 2)
    }

    @Test
    func onTapCallsGetCurrentPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.onTap()

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    func onTapAppliesEffectToPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        #expect(spy.addVideoTransformerCallCount == 0)

        sut.onTap()

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    func onTapCyclesEffectsAndCallsTransformersCorrectly() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        // None -> BlurLow: removes both keys, adds blur
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 1)
        #expect(spy.removeTransformerCallCount == 2)

        // BlurLow -> BlurHigh: removes both keys, adds blur
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 2)
        #expect(spy.removeTransformerCallCount == 4)

        // BlurHigh -> None: removes both keys, no add
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 2)
        #expect(spy.removeTransformerCallCount == 6)
    }

    @Test
    func onTapHandlesPublisherErrorGracefully() async throws {
        let sut = makeSUT(getCurrentPublisher: { throw Error.publisherError })

        // Should not crash
        sut.onTap()

        // State should still change
        #expect(sut.currentVideoEffect == .blurLow)
    }

    @Test
    func onTapHandlesTransformerErrorGracefully() async throws {
        let spy = PublisherSpy()
        spy.shouldThrowError = true
        let sut = makeSUT(getCurrentPublisher: { spy })

        // Should not crash
        sut.onTap()

        // State should still change
        #expect(sut.currentVideoEffect == .blurLow)
    }

    @Test
    func multipleTapsToggleThroughAllEffects() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        #expect(spy.addVideoTransformerCallCount == 0)
        #expect(sut.currentVideoEffect == .none)

        sut.onTap()  // none -> blurLow
        #expect(sut.currentVideoEffect == .blurLow)
        #expect(spy.addVideoTransformerCallCount == 1)

        sut.onTap()  // blurLow -> blurHigh
        #expect(sut.currentVideoEffect == .blurHigh)
        #expect(spy.addVideoTransformerCallCount == 2)

        sut.onTap()  // blurHigh -> none
        #expect(sut.currentVideoEffect == .none)
        #expect(spy.addVideoTransformerCallCount == 2)  // No change, only removes

        sut.onTap()  // none -> blurLow (cycle repeats)
        #expect(sut.currentVideoEffect == .blurLow)
        #expect(spy.addVideoTransformerCallCount == 3)
    }

    // MARK: - apply(_:) Tests

    @Test
    func applySetsEffectToNone() {
        let sut = makeSUT()
        sut.currentVideoEffect = .blurHigh

        sut.apply(.none)

        #expect(sut.currentVideoEffect == .none)
    }

    @Test
    func applySetsEffectToBlurLow() {
        let sut = makeSUT()

        sut.apply(.blurLow)

        #expect(sut.currentVideoEffect == .blurLow)
    }

    @Test
    func applySetsEffectToBlurHigh() {
        let sut = makeSUT()

        sut.apply(.blurHigh)

        #expect(sut.currentVideoEffect == .blurHigh)
    }

    @Test
    func applyAddsTransformerForBlurEffect() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.apply(.blurLow)

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    func applyNoneRemovesBothTransformersWithoutAdding() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.apply(.none)

        #expect(spy.addVideoTransformerCallCount == 0)
        #expect(spy.removeTransformerCallCount == 2)
    }

    @Test
    func applyHandlesTransformerErrorGracefully() {
        let spy = PublisherSpy()
        spy.shouldThrowError = true
        let sut = makeSUT(getCurrentPublisher: { spy })

        // Should not crash
        sut.apply(.blurHigh)

        // State should still be updated
        #expect(sut.currentVideoEffect == .blurHigh)
    }

    @Test
    func applyOverridesPreviousEffect() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.apply(.blurLow)
        #expect(sut.currentVideoEffect == .blurLow)

        sut.apply(.blurHigh)
        #expect(sut.currentVideoEffect == .blurHigh)

        sut.apply(.none)
        #expect(sut.currentVideoEffect == .none)
    }

    @Test
    func applyIsIndependentFromOnTapCycle() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        // Advance the onTap cycle to .blurLow
        sut.onTap()
        #expect(sut.currentVideoEffect == .blurLow)

        // apply() should set any effect directly
        sut.apply(.blurHigh)
        #expect(sut.currentVideoEffect == .blurHigh)

        // onTap() should now cycle from .blurHigh
        sut.onTap()
        #expect(sut.currentVideoEffect == .none)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        getCurrentPublisher: @escaping () throws -> VERAPublisher = { PublisherSpy() }
    ) -> BackgroundBlurButtonViewModel {
        BackgroundBlurButtonViewModel(getCurrentPublisher: getCurrentPublisher)
    }
}

// MARK: - Spies

final class PublisherSpy: VERAPublisher {
    var audioTransformers: [any VERATransformer] = []

    var transformerFactory: any VERATransformerFactory

    var view: AnyView { AnyView(EmptyView()) }

    var videoTransformers: [any VERATransformer] = []

    var setBackgroundBlurCallCount = 0
    var addVideoTransformerCallCount = 0
    var removeTransformerCallCount = 0
    var lastBlurLevel: BlurLevel?
    var shouldThrowError = false
    var audioLevelPublisher: AnyPublisher<Float, Never> = CurrentValueSubject(0).eraseToAnyPublisher()

    var publishAudio: Bool = true
    var publishVideo: Bool = true
    var cameraPosition: CameraPosition = .front

    func switchCamera(to cameraDeviceID: String) {}
    func cleanUp() {}

    init(
        transformerFactory: VERATransformerFactory = MockTransformerFactory()
    ) {
        self.transformerFactory = transformerFactory
    }

    func addVideoTransformer(_ transformer: any VERATransformer) {
        addVideoTransformerCallCount += 1
    }

    func setVideoTransformers(_ transformers: [any VERATransformer]) {
    }

    func removeTransformer(_ key: String) {
        removeTransformerCallCount += 1
    }

    func addAudioTransformer(_ transformer: any VERADomain.VERATransformer) {
    }

    func setAudioTransformers(_ transformers: [any VERADomain.VERATransformer]) {
    }

    func removeAudioTransformer(_ key: String) {
    }
}
