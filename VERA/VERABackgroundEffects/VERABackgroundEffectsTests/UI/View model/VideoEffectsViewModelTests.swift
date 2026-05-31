//
//  Created by Vonage on 31/05/2026.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERABackgroundEffects
import VERADomain
import VERATestHelpers

@Suite("VideoEffectsViewModel tests")
@MainActor
struct VideoEffectsViewModelTests {

    // MARK: - Initialization

    @Test("initial effect is loaded from repository")
    func initialEffectIsLoadedFromRepository() {
        let repo = MockVideoEffectRepository(storedEffect: .blurLow)
        let sut = makeSUT(videoEffectRepository: repo)

        #expect(sut.selectedEffect == .blurLow)
    }

    @Test("initial effect defaults to none when repository is empty")
    func initialEffectDefaultsToNone() {
        let sut = makeSUT()

        #expect(sut.selectedEffect == .none)
    }

    // MARK: - selectEffect

    @Test("selectEffect updates selectedEffect")
    func selectEffectUpdatesSelectedEffect() {
        let sut = makeSUT()

        sut.selectEffect(.blurHigh)

        #expect(sut.selectedEffect == .blurHigh)
    }

    @Test("selectEffect persists to repository")
    func selectEffectPersistsToRepository() {
        let repo = MockVideoEffectRepository()
        let sut = makeSUT(videoEffectRepository: repo)

        sut.selectEffect(.blurLow)

        #expect(repo.savedEffect == .blurLow)
    }

    @Test("selectEffect applies to publisher")
    func selectEffectAppliesToPublisher() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.selectEffect(.blurLow)

        #expect(spy.addVideoTransformerCallCount == 1)
    }

    @Test("selectEffect none removes transformers without adding")
    func selectEffectNoneRemovesTransformers() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.selectEffect(.none)

        #expect(spy.addVideoTransformerCallCount == 0)
        #expect(spy.removeTransformerCallCount == 2)
    }

    // MARK: - selectBackground

    @Test("selectBackground sets backgroundImage effect")
    func selectBackgroundSetsBackgroundImageEffect() {
        let sut = makeSUT()
        let item = VideoBackgroundItem(
            id: "bg_test", imagePath: "/path/test.jpg", isUserUploaded: false)

        sut.selectBackground(item)

        #expect(sut.selectedEffect == .backgroundImage(id: "bg_test", imagePath: "/path/test.jpg"))
    }

    @Test("selectBackground applies replacement transformer")
    func selectBackgroundAppliesReplacementTransformer() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })
        let item = VideoBackgroundItem(
            id: "bg_test", imagePath: "/path/test.jpg", isUserUploaded: false)

        sut.selectBackground(item)

        #expect(spy.addVideoTransformerCallCount == 1)
        #expect(spy.removeTransformerCallCount == 2)
    }

    // MARK: - loadBackgrounds

    @Test("loadBackgrounds populates backgrounds array")
    func loadBackgroundsPopulatesArray() {
        let stockRepo = MockBackgroundEffectsRepository(items: [
            VideoBackgroundItem(id: "bg_1", imagePath: "/p/1.jpg", isUserUploaded: false)
        ])
        let userRepo = MockUserBackgroundRepository(items: [
            VideoBackgroundItem(id: "user_1", imagePath: "/p/u1.jpg", isUserUploaded: true)
        ])
        let sut = makeSUT(
            backgroundEffectsRepository: stockRepo,
            userBackgroundRepository: userRepo
        )

        sut.loadBackgrounds()

        #expect(sut.backgrounds.count == 2)
        #expect(sut.backgrounds[0].id == "bg_1")
        #expect(sut.backgrounds[1].id == "user_1")
    }

    @Test("loadBackgrounds sets remainingSlots")
    func loadBackgroundsSetsRemainingSlots() {
        let userRepo = MockUserBackgroundRepository(items: [])
        let sut = makeSUT(userBackgroundRepository: userRepo)

        sut.loadBackgrounds()

        #expect(sut.remainingSlots == 10)
    }

    // MARK: - deleteBackground

    @Test("deleteBackground removes item from backgrounds")
    func deleteBackgroundRemovesItem() {
        let userItem = VideoBackgroundItem(
            id: "user_1", imagePath: "/p/u1.jpg", isUserUploaded: true)
        let userRepo = MockUserBackgroundRepository(items: [userItem])
        let sut = makeSUT(userBackgroundRepository: userRepo)
        sut.loadBackgrounds()

        sut.deleteBackground(userItem)

        #expect(!sut.backgrounds.contains(where: { $0.id == "user_1" }))
    }

    @Test("deleteBackground resets effect if deleted background was active")
    func deleteBackgroundResetsActiveEffect() {
        let spy = PublisherSpy()
        let userItem = VideoBackgroundItem(
            id: "user_1", imagePath: "/p/u1.jpg", isUserUploaded: true)
        let repo = MockVideoEffectRepository(
            storedEffect: .backgroundImage(id: "user_1", imagePath: "/p/u1.jpg"))
        let userRepo = MockUserBackgroundRepository(items: [userItem])
        let sut = makeSUT(
            getCurrentPublisher: { spy },
            userBackgroundRepository: userRepo,
            videoEffectRepository: repo
        )
        sut.loadBackgrounds()
        sut.selectBackground(userItem)

        sut.deleteBackground(userItem)

        #expect(sut.selectedEffect == .none)
    }

    @Test("deleteBackground ignores stock items")
    func deleteBackgroundIgnoresStockItems() {
        let stockItem = VideoBackgroundItem(
            id: "bg_1", imagePath: "/p/1.jpg", isUserUploaded: false)
        let stockRepo = MockBackgroundEffectsRepository(items: [stockItem])
        let sut = makeSUT(backgroundEffectsRepository: stockRepo)
        sut.loadBackgrounds()

        sut.deleteBackground(stockItem)

        #expect(sut.backgrounds.contains(where: { $0.id == "bg_1" }))
    }

    // MARK: - isSheetPresented

    @Test("isSheetPresented defaults to false")
    func isSheetPresentedDefaultsToFalse() {
        let sut = makeSUT()

        #expect(!sut.isSheetPresented)
    }

    // MARK: - errorMessage

    @Test("errorMessage defaults to nil")
    func errorMessageDefaultsToNil() {
        let sut = makeSUT()

        #expect(sut.errorMessage == nil)
    }

    // MARK: - publisher error handling

    @Test("selectEffect handles publisher error gracefully")
    func selectEffectHandlesPublisherError() {
        let sut = makeSUT(getCurrentPublisher: { throw TestError.publisherError })

        sut.selectEffect(.blurLow)

        #expect(sut.selectedEffect == .blurLow)
    }

    // MARK: - reapplyCurrentEffect

    @Test("reapplyCurrentEffect applies persisted effect to publisher")
    func reapplyCurrentEffectAppliesPersistedEffect() {
        let spy = PublisherSpy()
        let repo = MockVideoEffectRepository(storedEffect: .blurHigh)
        let sut = makeSUT(getCurrentPublisher: { spy }, videoEffectRepository: repo)

        sut.reapplyCurrentEffect()

        #expect(spy.addVideoTransformerCallCount == 1)
        #expect(spy.removeTransformerCallCount == 2)
    }

    @Test("reapplyCurrentEffect with none only removes transformers")
    func reapplyCurrentEffectWithNoneOnlyRemoves() {
        let spy = PublisherSpy()
        let sut = makeSUT(getCurrentPublisher: { spy })

        sut.reapplyCurrentEffect()

        #expect(spy.addVideoTransformerCallCount == 0)
        #expect(spy.removeTransformerCallCount == 2)
    }

    // MARK: - showMaxImagesError

    @Test("showMaxImagesError sets errorMessage")
    func showMaxImagesErrorSetsErrorMessage() {
        let sut = makeSUT()

        sut.showMaxImagesError()

        #expect(sut.errorMessage != nil)
        #expect(sut.errorMessage?.contains("10") == true)
    }

    @Test("showMaxImagesError can be dismissed by clearing errorMessage")
    func showMaxImagesErrorCanBeDismissed() {
        let sut = makeSUT()

        sut.showMaxImagesError()
        sut.errorMessage = nil

        #expect(sut.errorMessage == nil)
    }

    // MARK: - addBackgrounds

    @Test("addBackgrounds appends items and selects last added")
    func addBackgroundsAppendsAndSelects() async {
        let spy = PublisherSpy()
        let userRepo = MockUserBackgroundRepository()
        let sut = makeSUT(getCurrentPublisher: { spy }, userBackgroundRepository: userRepo)

        let loaders: [PhotoItemDataLoader] = [
            MockPhotoItemDataLoader(data: Data([0xFF, 0xD8]))
        ]

        sut.addBackgrounds(loaders)
        await delay()

        #expect(sut.backgrounds.count == 1)
        if case .backgroundImage = sut.selectedEffect {
            // correct
        } else {
            Issue.record("Expected backgroundImage effect, got \(sut.selectedEffect)")
        }
    }

    @Test("addBackgrounds skips items with nil data")
    func addBackgroundsSkipsNilData() async {
        let userRepo = MockUserBackgroundRepository()
        let sut = makeSUT(userBackgroundRepository: userRepo)

        let loaders: [PhotoItemDataLoader] = [
            MockPhotoItemDataLoader(data: nil)
        ]

        sut.addBackgrounds(loaders)
        await delay()

        #expect(sut.backgrounds.isEmpty)
    }

    @Test("addBackgrounds shows error when max slots reached")
    func addBackgroundsShowsMaxError() async {
        let existingItems = (0..<10).map {
            VideoBackgroundItem(id: "user_\($0)", imagePath: "/p/\($0).jpg", isUserUploaded: true)
        }
        let userRepo = MockUserBackgroundRepository(items: existingItems)
        let sut = makeSUT(userBackgroundRepository: userRepo)

        let loaders: [PhotoItemDataLoader] = [
            MockPhotoItemDataLoader(data: Data([0xFF, 0xD8]))
        ]

        sut.addBackgrounds(loaders)
        await delay()

        #expect(sut.errorMessage != nil)
    }

    // MARK: - Test Helpers

    private enum TestError: Error {
        case publisherError
    }

    private func makeSUT(
        getCurrentPublisher: @escaping () throws -> VERAPublisher = { PublisherSpy() },
        backgroundEffectsRepository: BackgroundEffectsRepository = MockBackgroundEffectsRepository(),
        userBackgroundRepository: UserBackgroundRepository = MockUserBackgroundRepository(),
        videoEffectRepository: VideoEffectRepository = MockVideoEffectRepository()
    ) -> VideoEffectsViewModel {
        let getBackgrounds = GetBackgroundsUseCase(
            backgroundEffectsRepository: backgroundEffectsRepository,
            userBackgroundRepository: userBackgroundRepository
        )
        let addBackground = AddBackgroundUseCase(
            userBackgroundRepository: userBackgroundRepository
        )
        let deleteBackground = DeleteBackgroundUseCase(
            userBackgroundRepository: userBackgroundRepository,
            videoEffectRepository: videoEffectRepository
        )
        return VideoEffectsViewModel(
            getCurrentPublisher: getCurrentPublisher,
            getBackgroundsUseCase: getBackgrounds,
            addBackgroundUseCase: addBackground,
            deleteBackgroundUseCase: deleteBackground,
            videoEffectRepository: videoEffectRepository
        )
    }
}

// MARK: - Mocks

private final class MockBackgroundEffectsRepository: BackgroundEffectsRepository {
    let items: [VideoBackgroundItem]

    init(items: [VideoBackgroundItem] = []) {
        self.items = items
    }

    func availableBackgrounds() throws -> [VideoBackgroundItem] {
        items
    }
}

private final class MockUserBackgroundRepository: UserBackgroundRepository {
    static let maxUserBackgrounds = 10

    var items: [VideoBackgroundItem]
    var deletedIds: [String] = []

    init(items: [VideoBackgroundItem] = []) {
        self.items = items
    }

    func savedBackgrounds() throws -> [VideoBackgroundItem] {
        items
    }

    func save(_ imageData: Data) throws -> VideoBackgroundItem {
        let item = VideoBackgroundItem(
            id: "user_bg_\(items.count)", imagePath: "/tmp/saved.jpg", isUserUploaded: true)
        items.append(item)
        return item
    }

    func delete(_ id: String) throws {
        deletedIds.append(id)
        items.removeAll { $0.id == id }
    }

    var remainingSlots: Int {
        max(0, Self.maxUserBackgrounds - items.count)
    }
}

private final class MockVideoEffectRepository: VideoEffectRepository {
    var savedEffect: VideoEffect?
    private let storedEffect: VideoEffect

    init(storedEffect: VideoEffect = .none) {
        self.storedEffect = storedEffect
    }

    func save(_ effect: VideoEffect) {
        savedEffect = effect
    }

    func load() -> VideoEffect {
        savedEffect ?? storedEffect
    }
}

// MARK: - Publisher Spy

private final class PublisherSpy: VERAPublisher {
    var audioTransformers: [VERATransformer] = []
    var transformerFactory: VERATransformerFactory = MockTransformerFactory()
    var view: AnyView { AnyView(EmptyView()) }
    var videoTransformers: [VERATransformer] = []
    var addVideoTransformerCallCount = 0
    var removeTransformerCallCount = 0
    var audioLevelPublisher: AnyPublisher<Float, Never> = CurrentValueSubject(0).eraseToAnyPublisher()
    var publishAudio: Bool = true
    var publishVideo: Bool = true
    var cameraPosition: CameraPosition = .front

    func switchCamera(to cameraDeviceID: String) {}
    func cleanUp() {}

    func addVideoTransformer(_ transformer: VERATransformer) {
        addVideoTransformerCallCount += 1
    }

    func setVideoTransformers(_ transformers: [VERATransformer]) {}

    func removeTransformer(_ key: String) {
        removeTransformerCallCount += 1
    }

    func addAudioTransformer(_ transformer: VERATransformer) {}
    func setAudioTransformers(_ transformers: [VERATransformer]) {}
    func removeAudioTransformer(_ key: String) {}
}

// MARK: - Photo Item Mock

private struct MockPhotoItemDataLoader: PhotoItemDataLoader {
    let data: Data?
    func loadImageData() async throws -> Data? { data }
}
