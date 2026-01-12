//
//  Created by Vonage on 6/8/25.
//

import Foundation
import Testing
import VERAArchiving
import VERACore
import VERADomain
import VERATestHelpers
import VERAVonage

@Suite("Default archive recordings repository tests")
struct DefaultArchiveRecordingsRepositoryTests {

    @Test("Should return cached recording if file exists locally")
    func returnsCachedRecordingIfFileExistsLocally() async throws {
        let tempDir = try createTempDirectory()
        let archive = makeArchive(url: URL(string: "https://example.com/video.mp4")!)
        let expectedLocalURL = tempDir.appendingPathComponent("\(archive.id.uuidString).mp4")

        // Create a fake local file
        try "fake video data".write(to: expectedLocalURL, atomically: true, encoding: .utf8)

        let mockHTTP = MockHTTPClient()
        let sut = makeSUT(httpClient: mockHTTP, cacheDirectory: tempDir)

        let recording = try await sut.getRecording(archive)

        #expect(recording.url == expectedLocalURL)
        #expect(mockHTTP.callCount == 0)  // Should not make HTTP request
    }

    @Test("Should download and cache recording if not exists locally")
    func downloadsAndCachesRecordingIfNotExistsLocally() async throws {
        let tempDir = try createTempDirectory()
        let archive = makeArchive(url: URL(string: "https://example.com/video.mp4")!)
        let expectedLocalURL = tempDir.appendingPathComponent("\(archive.id.uuidString).mp4")
        let fakeVideoData = "fake video content".data(using: .utf8)!

        let mockHTTP = MockHTTPClient()
        mockHTTP.data = fakeVideoData

        let sut = makeSUT(httpClient: mockHTTP, cacheDirectory: tempDir)

        let recording = try await sut.getRecording(archive)

        #expect(recording.url == expectedLocalURL)
        #expect(mockHTTP.callCount == 1)
        #expect(mockHTTP.recordedURL == archive.url)

        // Check file was saved locally
        let savedData = try Data(contentsOf: expectedLocalURL)
        #expect(savedData == fakeVideoData)
    }

    @Test("Should return same recording for multiple concurrent requests")
    func returnsSameRecordingForMultipleConcurrentRequests() async throws {
        let tempDir = try createTempDirectory()
        let archive = makeArchive(url: URL(string: "https://example.com/video.mp4")!)
        let fakeVideoData = "fake video content".data(using: .utf8)!

        let mockHTTP = MockHTTPClient()
        mockHTTP.data = fakeVideoData
        mockHTTP.delaySeconds = 0.1  // Add small delay to test concurrency

        let sut = makeSUT(httpClient: mockHTTP, cacheDirectory: tempDir)

        // Start multiple concurrent requests
        async let recording1 = sut.getRecording(archive)
        async let recording2 = sut.getRecording(archive)
        async let recording3 = sut.getRecording(archive)

        let results = try await [recording1, recording2, recording3]

        // All should return the same URL
        #expect(results[0].url == results[1].url)
        #expect(results[1].url == results[2].url)

        // Should only make one HTTP request
        #expect(mockHTTP.callCount == 1)
    }

    @Test("Should throw error if archive has no download URL")
    func throwsErrorIfArchiveHasNoDownloadURL() async throws {
        let tempDir = try createTempDirectory()
        let archive = makeArchive(url: nil)  // No URL

        let mockHTTP = MockHTTPClient()
        let sut = makeSUT(httpClient: mockHTTP, cacheDirectory: tempDir)

        await #expect(throws: ArchiveRecordingError.noDownloadURL) {
            _ = try await sut.getRecording(archive)
        }
    }

    @Test("Should throw error if download fails")
    func throwsErrorIfDownloadFails() async throws {
        let tempDir = try createTempDirectory()
        let archive = makeArchive(url: URL(string: "https://example.com/video.mp4")!)

        let mockHTTP = MockHTTPClient()
        mockHTTP.shouldThrowError = true

        let sut = makeSUT(httpClient: mockHTTP, cacheDirectory: tempDir)

        await #expect(throws: MockHTTPError.self) {
            _ = try await sut.getRecording(archive)
        }
    }

    @Test("Should use default cache directory if none provided")
    func usesDefaultCacheDirectoryIfNoneProvided() async throws {
        let mockHTTP = MockHTTPClient()
        let sut = DefaultArchiveRecordingsRepository(httpClient: mockHTTP)

        // Create a test archive to trigger cache directory usage
        let archive = makeArchive(url: URL(string: "https://example.com/video.mp4")!)
        let fakeVideoData = "fake video content".data(using: .utf8)!

        mockHTTP.data = fakeVideoData

        // This should work without throwing, indicating the default cache directory was created
        let recording = try await sut.getRecording(archive)

        // Verify the recording was created successfully
        #expect(recording.url.lastPathComponent == "\(archive.id.uuidString).mp4")
        #expect(mockHTTP.callCount == 1)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        httpClient: HTTPClient = MockHTTPClient(),
        fileManager: FileManager = .default,
        cacheDirectory: URL? = nil
    ) -> DefaultArchiveRecordingsRepository {
        DefaultArchiveRecordingsRepository(
            httpClient: httpClient,
            fileManager: fileManager,
            cacheDirectory: cacheDirectory
        )
    }

    private func makeArchive(
        id: UUID = UUID(),
        name: String = "Test Archive",
        status: ArchiveStatus = .available,
        url: URL?
    ) -> Archive {
        Archive(
            id: id,
            name: name,
            createdAt: Date(),
            status: status,
            url: url
        )
    }

    private func createTempDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveRecordingsTests")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        return tempDir
    }
}
