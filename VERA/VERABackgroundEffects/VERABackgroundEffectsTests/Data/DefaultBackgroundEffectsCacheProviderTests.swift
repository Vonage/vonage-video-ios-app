//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import Testing
import VERABackgroundEffects

@Suite("DefaultBackgroundEffectsCacheProvider tests")
struct DefaultBackgroundEffectsCacheProviderTests {

    @Test("ensureCacheDirectory creates directory when needed")
    func ensureCacheDirectoryCreatesDirectoryWhenNeeded() throws {
        let pathComponent = makePathComponent()
        let sut = DefaultBackgroundEffectsCacheProvider(
            fileManager: .default,
            pathComponent: pathComponent
        )
        let directory = cachesDirectory.appendingPathComponent(pathComponent, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(!FileManager.default.fileExists(atPath: directory.path))

        try sut.ensureCacheDirectory()

        #expect(FileManager.default.fileExists(atPath: directory.path))
    }

    @Test("cachedFileURL appends jpg filename")
    func cachedFileURLAppendsJPGFilename() throws {
        let pathComponent = makePathComponent()
        let sut = DefaultBackgroundEffectsCacheProvider(
            fileManager: .default,
            pathComponent: pathComponent
        )
        let expectedURL =
            cachesDirectory
            .appendingPathComponent(pathComponent, isDirectory: true)
            .appendingPathComponent("bg_test.jpg")

        #expect(try sut.cachedFileURL(for: "bg_test") == expectedURL)
    }

    @Test("cachedFileExists returns true only when file exists")
    func cachedFileExistsReturnsTrueOnlyWhenFileExists() throws {
        let pathComponent = makePathComponent()
        let sut = DefaultBackgroundEffectsCacheProvider(
            fileManager: .default,
            pathComponent: pathComponent
        )
        let directory = cachesDirectory.appendingPathComponent(pathComponent, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try sut.ensureCacheDirectory()
        #expect(try !sut.cachedFileExists(for: "bg_test"))

        try Data([0xFF]).write(to: try sut.cachedFileURL(for: "bg_test"))

        #expect(try sut.cachedFileExists(for: "bg_test"))
    }

    @Test("throws when cache directory is unavailable")
    func throwsWhenCacheDirectoryIsUnavailable() throws {
        let sut = DefaultBackgroundEffectsCacheProvider(
            fileManager: EmptySearchPathFileManager(),
            pathComponent: makePathComponent()
        )

        #expect(throws: BackgroundEffectsCacheProviderError.cacheDirectoryUnavailable) {
            try sut.ensureCacheDirectory()
        }

        #expect(throws: BackgroundEffectsCacheProviderError.cacheDirectoryUnavailable) {
            _ = try sut.cachedFileURL(for: "bg_test")
        }
    }

    // MARK: - Helpers

    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private func makePathComponent() -> String {
        "test_video_backgrounds_\(UUID().uuidString)"
    }

    private final class EmptySearchPathFileManager: FileManager {
        override func urls(
            for directory: FileManager.SearchPathDirectory,
            in domainMask: FileManager.SearchPathDomainMask
        ) -> [URL] {
            []
        }
    }
}
