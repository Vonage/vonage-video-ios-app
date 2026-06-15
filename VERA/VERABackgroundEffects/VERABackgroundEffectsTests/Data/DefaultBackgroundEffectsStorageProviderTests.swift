//
//  Created by Vonage on 31/05/2026.
//

import Foundation
import Testing
import VERABackgroundEffects

@Suite("DefaultBackgroundEffectsStorageProvider tests")
struct DefaultBackgroundEffectsStorageProviderTests {

    @Test("ensureDirectory creates directory when needed")
    func ensureDirectoryCreatesDirectoryWhenNeeded() throws {
        let pathComponent = makePathComponent()
        let sut = makeSUT(pathComponent: pathComponent)
        let directory = cachesDirectory.appendingPathComponent(pathComponent, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(!FileManager.default.fileExists(atPath: directory.path))

        try sut.ensureDirectory()

        #expect(FileManager.default.fileExists(atPath: directory.path))
    }

    @Test("fileURL appends jpg filename")
    func fileURLAppendsJPGFilename() throws {
        let pathComponent = makePathComponent()
        let sut = makeSUT(pathComponent: pathComponent)
        let expectedURL =
            cachesDirectory
            .appendingPathComponent(pathComponent, isDirectory: true)
            .appendingPathComponent("bg_test.jpg")

        #expect(try sut.fileURL(for: "bg_test") == expectedURL)
    }

    @Test("fileExists returns true only when file exists")
    func fileExistsReturnsTrueOnlyWhenFileExists() throws {
        let pathComponent = makePathComponent()
        let sut = makeSUT(pathComponent: pathComponent)
        let directory = cachesDirectory.appendingPathComponent(pathComponent, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try sut.ensureDirectory()
        #expect(try !sut.fileExists(for: "bg_test"))

        try Data([0xFF]).write(to: try sut.fileURL(for: "bg_test"))

        #expect(try sut.fileExists(for: "bg_test"))
    }

    @Test("contentsOfDirectory returns files")
    func contentsOfDirectoryReturnsFiles() throws {
        let pathComponent = makePathComponent()
        let sut = makeSUT(pathComponent: pathComponent)
        let directory = cachesDirectory.appendingPathComponent(pathComponent, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try sut.ensureDirectory()
        try Data([0xFF]).write(to: try sut.fileURL(for: "bg_test"))

        let files = try sut.contentsOfDirectory(
            includingPropertiesForKeys: [],
            options: .skipsHiddenFiles
        )

        #expect(files.map(\.lastPathComponent) == ["bg_test.jpg"])
    }

    @Test("removeFile removes file")
    func removeFileRemovesFile() throws {
        let pathComponent = makePathComponent()
        let sut = makeSUT(pathComponent: pathComponent)
        let directory = cachesDirectory.appendingPathComponent(pathComponent, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try sut.ensureDirectory()
        try Data([0xFF]).write(to: try sut.fileURL(for: "bg_test"))

        try sut.removeFile(for: "bg_test")

        #expect(try !sut.fileExists(for: "bg_test"))
    }

    @Test("throws when directory is unavailable")
    func throwsWhenDirectoryIsUnavailable() throws {
        let sut = DefaultBackgroundEffectsStorageProvider(
            fileManager: EmptySearchPathFileManager(),
            searchPathDirectory: .cachesDirectory,
            pathComponent: makePathComponent()
        )

        #expect(throws: BackgroundEffectsStorageProviderError.directoryUnavailable) {
            try sut.ensureDirectory()
        }

        #expect(throws: BackgroundEffectsStorageProviderError.directoryUnavailable) {
            _ = try sut.fileURL(for: "bg_test")
        }
    }

    // MARK: - Helpers

    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private func makeSUT(pathComponent: String) -> DefaultBackgroundEffectsStorageProvider {
        DefaultBackgroundEffectsStorageProvider(
            fileManager: .default,
            searchPathDirectory: .cachesDirectory,
            pathComponent: pathComponent
        )
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
