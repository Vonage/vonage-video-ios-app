//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import Testing
import VERADomain

@testable import VERABackgroundEffects

@Suite("DefaultBackgroundEffectsRepository tests")
struct DefaultBackgroundEffectsRepositoryTests {

    @Test("availableBackgrounds ensures cache directory")
    func availableBackgroundsEnsuresCacheDirectory() throws {
        let cacheProvider = MockBackgroundEffectsCacheProvider()
        let sut = DefaultBackgroundEffectsRepository(
            bundle: .init(for: DefaultBackgroundEffectsRepository.self),
            cacheProvider: cacheProvider
        )

        _ = try sut.availableBackgrounds()

        #expect(cacheProvider.ensureCacheDirectoryCallCount == 1)
    }

    @Test("availableBackgrounds returns cached items from cache provider")
    func availableBackgroundsReturnsCachedItemsFromCacheProvider() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_stock_bg_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let cacheProvider = MockBackgroundEffectsCacheProvider(directory: directory)
        cacheProvider.existingAssetNames = Set(DefaultBackgroundEffectsRepository.stockAssetNames)
        let sut = DefaultBackgroundEffectsRepository(
            bundle: .init(for: DefaultBackgroundEffectsRepository.self),
            cacheProvider: cacheProvider
        )

        let items = try sut.availableBackgrounds()

        #expect(items.count == DefaultBackgroundEffectsRepository.stockAssetNames.count)
        #expect(items.allSatisfy { !$0.isUserUploaded })
        #expect(items.allSatisfy { $0.thumbnailResource == $0.id })
        #expect(items.allSatisfy { $0.imagePath.hasPrefix(directory.path) })
    }

    // MARK: - Helpers

    private final class MockBackgroundEffectsCacheProvider: BackgroundEffectsCacheProviding {
        var ensureCacheDirectoryCallCount = 0
        var existingAssetNames: Set<String> = []

        private let directory: URL

        init(directory: URL = FileManager.default.temporaryDirectory) {
            self.directory = directory
        }

        func ensureCacheDirectory() throws {
            ensureCacheDirectoryCallCount += 1
        }

        func cachedFileURL(for assetName: String) throws -> URL {
            directory.appendingPathComponent("\(assetName).jpg")
        }

        func cachedFileExists(for assetName: String) throws -> Bool {
            existingAssetNames.contains(assetName)
        }
    }
}
