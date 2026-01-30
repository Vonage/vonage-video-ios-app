//
//  Created by Vonage on 29/1/26.
//

import Foundation
import SwiftUI
import Testing
import VERABackgroundEffects
import VERADomain

@Suite("BackgroundBlurButtonViewModel tests")
struct BackgroundBlurButtonViewModelTests {

    enum Error: Swift.Error {
        case nilValue
        case publisherError
        case blurError
    }

    @Test
    @MainActor
    func initialBlurLevelIsNone() async throws {
        let sut = makeSUT()

        #expect(sut.currentBlurLevel == .none)
    }

    @Test
    @MainActor
    func onTapCyclesFromNoneToLow() async throws {
        let sut = makeSUT()

        #expect(sut.currentBlurLevel == .none)

        sut.onTap()

        #expect(sut.currentBlurLevel == .low)
    }

    @Test
    @MainActor
    func onTapCyclesFromLowToHigh() async throws {
        let sut = makeSUT()
        sut.currentBlurLevel = .low

        sut.onTap()

        #expect(sut.currentBlurLevel == .high)
    }

    @Test
    @MainActor
    func onTapCyclesFromHighToNone() async throws {
        let sut = makeSUT()
        sut.currentBlurLevel = .high

        sut.onTap()

        #expect(sut.currentBlurLevel == .none)
    }

    @Test
    @MainActor
    func onTapCallsGetCurrentPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.onTap()

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    @MainActor
    func onTapAppliesBlurToPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        #expect(spy.addVideoTransformerCallCount == 0)

        sut.onTap()

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test
    @MainActor
    func onTapAppliesCorrectBlurLevelToPublisher() async throws {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        // None -> Low
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 1)
        #expect(spy.removeTransformerCallCount == 1)

        // Low -> High
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 2)
        #expect(spy.removeTransformerCallCount == 2)

        // High -> None (solo remove, no add)
        sut.onTap()
        #expect(spy.addVideoTransformerCallCount == 2)
        #expect(spy.removeTransformerCallCount == 3)
    }

    @Test
    @MainActor
    func onTapHandlesPublisherErrorGracefully() async throws {
        let sut = makeSUT(getCurrentPublisher: { throw Error.publisherError })

        // Should not crash
        sut.onTap()

        // State should still change
        #expect(sut.currentBlurLevel == .low)
    }

    @Test
    @MainActor
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
    @MainActor
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

    // MARK: - Test Helpers

    private func makeSUT(
        getCurrentPublisher: @escaping () throws -> VERAPublisher = { PublisherSpy() }
    ) -> BackgroundBlurButtonViewModel {
        BackgroundBlurButtonViewModel(getCurrentPublisher: getCurrentPublisher)
    }
}

// MARK: - Spies

final class PublisherSpy: VERAPublisher {
    var transformerFactory: any VERADomain.VERATransformerFactory

    var view: AnyView { AnyView(EmptyView()) }

    var videoTransformers: [any VERADomain.VERATransformer] = []

    func addVideoTransformer(_ transformer: any VERADomain.VERATransformer) {
        addVideoTransformerCallCount += 1
    }

    func addVideoTransformers(_ transformers: [any VERADomain.VERATransformer]) {
    }

    func removeTransformer(_ key: String) {
        removeTransformerCallCount += 1
    }

    var setBackgroundBlurCallCount = 0
    var addVideoTransformerCallCount = 0
    var removeTransformerCallCount = 0
    var lastBlurLevel: BlurLevel? = nil
    var shouldThrowError = false

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
}

public final class MockTransformer: VERATransformer {
    public var key: String
    public var transformer: AnyObject

    public init(
        key: String = "anyKey",
        transformer: AnyObject
    ) {
        self.key = key
        self.transformer = transformer
    }
}

public final class MockTransformerFactory: VERATransformerFactory {
    public func makeTransformer(
        for key: String,
        params: String
    ) throws -> any VERADomain.VERATransformer {
        MockTransformer(key: key, transformer: NSObject())
    }
}
