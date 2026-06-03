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
        let storageProvider = MockBackgroundEffectsStorageProvider()
        let sut = DefaultBackgroundEffectsRepository(
            bundle: .init(for: DefaultBackgroundEffectsRepository.self),
            storageProvider: storageProvider
        )

        _ = try sut.availableBackgrounds()

        #expect(storageProvider.ensureDirectoryCallCount == 1)
    }

    @Test("availableBackgrounds returns cached items from storage provider")
    func availableBackgroundsReturnsCachedItemsFromStorageProvider() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_stock_bg_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let storageProvider = MockBackgroundEffectsStorageProvider(directory: directory)
        storageProvider.existingIDs = Set(DefaultBackgroundEffectsRepository.stockAssetNames)
        let sut = DefaultBackgroundEffectsRepository(
            bundle: .init(for: DefaultBackgroundEffectsRepository.self),
            storageProvider: storageProvider
        )

        let items = try sut.availableBackgrounds()

        #expect(items.count == DefaultBackgroundEffectsRepository.stockAssetNames.count)
        #expect(items.allSatisfy { !$0.isUserUploaded })
        #expect(items.allSatisfy { $0.thumbnailResource == $0.id })
        #expect(items.allSatisfy { $0.imagePath.hasPrefix(directory.path) })
    }

    @Test("availableBackgrounds throws when stock asset is missing")
    func availableBackgroundsThrowsWhenStockAssetIsMissing() throws {
        let bundleDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_empty_bundle_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleDirectory) }

        let sut = DefaultBackgroundEffectsRepository(
            bundle: try #require(Bundle(path: bundleDirectory.path)),
            storageProvider: MockBackgroundEffectsStorageProvider()
        )

        #expect(throws: BackgroundEffectsRepositoryError.assetNotFound(assetName: "bg_bookshelf_room")) {
            _ = try sut.availableBackgrounds()
        }
    }

    // MARK: - Helpers

    private final class MockBackgroundEffectsStorageProvider: BackgroundEffectsStorageProviding {
        var ensureDirectoryCallCount = 0
        var existingIDs: Set<String> = []

        private let directory: URL

        init(directory: URL = FileManager.default.temporaryDirectory) {
            self.directory = directory
        }

        func ensureDirectory() throws {
            ensureDirectoryCallCount += 1
        }

        func fileURL(for id: String) throws -> URL {
            directory.appendingPathComponent("\(id).jpg")
        }

        func fileExists(for id: String) throws -> Bool {
            existingIDs.contains(id)
        }

        func contentsOfDirectory(
            includingPropertiesForKeys keys: [URLResourceKey],
            options: FileManager.DirectoryEnumerationOptions
        ) throws -> [URL] {
            []
        }

        func removeFile(for id: String) throws {
            existingIDs.remove(id)
        }
    }
}
