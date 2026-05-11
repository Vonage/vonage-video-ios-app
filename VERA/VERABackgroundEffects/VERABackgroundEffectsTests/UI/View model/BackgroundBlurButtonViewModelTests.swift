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
    func initialBlurLevelIsNone() async throws {
        let sut = makeSUT()

        #expect(sut.currentBlurLevel == .none)
    }

    @Test
    func onTapCyclesFromNoneToLow() async throws {
        let sut = makeSUT()

        #expect(sut.currentBlurLevel == .none)

        sut.onTap()

        #expect(sut.currentBlurLevel == .low)
    }

    @Test
    func onTapCyclesFromLowToHigh() async throws {
        let sut = makeSUT()
        sut.currentBlurLevel = .low

        sut.onTap()

        #expect(sut.currentBlurLevel == .high)
    }

    @Test
    func onTapCyclesFromHighToNone() async throws {
        let sut = makeSUT()
        sut.currentBlurLevel = .high

        sut.onTap()

        #expect(sut.currentBlurLevel == .none)
    }

    @Test
    func onTapCallsGetCurrentPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.onTap()

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    func onTapAppliesBlurToPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        #expect(spy.addVideoTransformerCallCount == 0)

        sut.onTap()

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    func onTapAppliesCorrectBlurLevelToPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        // setBackgroundBlur clears the Vonage, Apple Vision, and FrameCounter
        // transformer keys on every call so switching providers mid-effect leaves
        // no stale transformer. That means `removeTransformer` is invoked three
        // times per tap regardless of state. The FrameCounter is only chained when
        // the HUD is enabled, so `addVideoTransformer` is invoked once per non-none tap.

        // None -> Low
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 1)
        #expect(spy.removeTransformerCallCount == 3)

        // Low -> High
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 2)
        #expect(spy.removeTransformerCallCount == 6)

        // High -> None (solo remove, no add)
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 2)
        #expect(spy.removeTransformerCallCount == 9)
    }

    @Test
    func onTapHandlesPublisherErrorGracefully() async throws {
        let sut = makeSUT(getCurrentPublisher: { throw Error.publisherError })

        // Should not crash
        sut.onTap()

        // State should still change
        #expect(sut.currentBlurLevel == .low)
    }

    @Test
    func onTapHandlesBlurErrorGracefully() async throws {
        let spy = PublisherSpy()
        spy.shouldThrowError = true
        let sut = makeSUT(getCurrentPublisher: { spy })

        // Should not crash
        sut.onTap()

        // State should still change
        #expect(sut.currentBlurLevel == .low)
    }

    @Test
    func multipleTapsToggleThroughAllLevels() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        #expect(spy.addVideoTransformerCallCount == 0)

        #expect(sut.currentBlurLevel == .none)

        sut.onTap()  // none -> low
        #expect(sut.currentBlurLevel == .low)

        #expect(spy.addVideoTransformerCallCount == 1)

        sut.onTap()  // low -> high
        #expect(sut.currentBlurLevel == .high)

        #expect(spy.addVideoTransformerCallCount == 2)

        sut.onTap()  // high -> none
        #expect(sut.currentBlurLevel == .none)

        #expect(spy.addVideoTransformerCallCount == 2)  // No change, only remove

        sut.onTap()  // none -> low (cycle repeats)
        #expect(sut.currentBlurLevel == .low)

        #expect(spy.addVideoTransformerCallCount == 3)
    }

    // MARK: - update(blurLevel:) Tests

    @Test
    func updateSetsBlurLevelToNone() {
        let sut = makeSUT()
        sut.currentBlurLevel = .high

        sut.update(blurLevel: .none)

        #expect(sut.currentBlurLevel == .none)
    }

    @Test
    func updateSetsBlurLevelToLow() {
        let sut = makeSUT()

        sut.update(blurLevel: .low)

        #expect(sut.currentBlurLevel == .low)
    }

    @Test
    func updateSetsBlurLevelToHigh() {
        let sut = makeSUT()

        sut.update(blurLevel: .high)

        #expect(sut.currentBlurLevel == .high)
    }

    @Test
    func updateAppliesBlurLevelToPublisher() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.update(blurLevel: .low)

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    func updateToNoneRemovesTransformerWithoutAdding() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.update(blurLevel: .none)

        #expect(spy.addVideoTransformerCallCount == 0)
        // Three keys cleared (Vonage, Apple Vision, FrameCounter) regardless of state.
        #expect(spy.removeTransformerCallCount == 3)
    }

    @Test
    func updateHandlesBlurErrorGracefully() {
        let spy = PublisherSpy()
        spy.shouldThrowError = true
        let sut = makeSUT(getCurrentPublisher: { spy })

        // Should not crash
        sut.update(blurLevel: .high)

        // State should still be updated
        #expect(sut.currentBlurLevel == .high)
    }

    @Test
    func updateOverridesPreviousBlurLevel() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.update(blurLevel: .low)
        #expect(sut.currentBlurLevel == .low)

        sut.update(blurLevel: .high)
        #expect(sut.currentBlurLevel == .high)

        sut.update(blurLevel: .none)
        #expect(sut.currentBlurLevel == .none)
    }

    @Test
    func updateIsIndependentFromOnTapCycle() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        // Advance the onTap cycle to .low
        sut.onTap()
        #expect(sut.currentBlurLevel == .low)

        // update() should set any level directly
        sut.update(blurLevel: .high)
        #expect(sut.currentBlurLevel == .high)

        // onTap() should now cycle from .high
        sut.onTap()
        #expect(sut.currentBlurLevel == .none)
    }

    // MARK: - Provider/Quality closure tests

    @Test
    func onTapConsultsProviderAndQualityClosures() async throws {
        let spy = PublisherSpy()
        var providerCallCount = 0
        var qualityCallCount = 0

        let sut = BackgroundBlurButtonViewModel(
            getCurrentPublisher: { spy },
            getProvider: {
                providerCallCount += 1
                return .vonage
            },
            getAppleVisionQuality: {
                qualityCallCount += 1
                return .fast
            }
        )

        sut.onTap()  // none -> low triggers a set call

        #expect(providerCallCount == 1)
        #expect(qualityCallCount == 1)
    }

    @Test
    func onTapWithExplicitVonageProviderStillAddsBlurTransformer() async throws {
        let spy = PublisherSpy()
        let sut = BackgroundBlurButtonViewModel(
            getCurrentPublisher: { spy },
            getProvider: { .vonage }
        )

        sut.onTap()

        #expect(spy.addVideoTransformerCallCount == 1)
        #expect(sut.currentBlurLevel == .low)
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
