//
//  Created by Vonage on 26/10/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("RotatingLogFileSet Tests")
struct RotatingLogFileSetTests {

    // MARK: - Test Helpers

    private func makeDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("veralogger-rotation-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeSUT(
        directory: URL,
        maxFileSize: UInt64 = 10,
        maxFileCount: Int = 5
    ) -> RotatingLogFileSet {
        RotatingLogFileSet(directory: directory, maxFileSize: maxFileSize, maxFileCount: maxFileCount)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func contents(of url: URL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private func fileSize(of url: URL) -> UInt64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? UInt64 ?? 0
    }

    // MARK: - Writing

    @Test("Writing creates a single file named after the session timestamp")
    func writeCreatesFirstFile() async throws {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)

        await sut.write(Data("hello".utf8))
        let urls = await sut.fileURLs()

        let url = try #require(urls.first)
        #expect(urls.count == 1)
        #expect(url.lastPathComponent.hasSuffix("_log.1"))
        #expect(contents(of: url) == "hello")
    }

    @Test("Writes that fit the limit are appended to the same file")
    func appendsWhileUnderLimit() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)

        await sut.write(Data("abc".utf8))
        await sut.write(Data("def".utf8))
        let urls = await sut.fileURLs()

        #expect(urls.count == 1)
        #expect(contents(of: urls[0]) == "abcdef")
    }

    @Test("Exceeding the size limit continues in the next file of the same session")
    func rotatesToNextFile() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)

        await sut.write(Data("0123456789".utf8))
        await sut.write(Data("next".utf8))
        let urls = await sut.fileURLs()

        #expect(urls.count == 2)
        #expect(urls[0].lastPathComponent.hasSuffix("_log.1"))
        #expect(urls[1].lastPathComponent.hasSuffix("_log.2"))
        #expect(contents(of: urls[1]) == "next")
        // The five files of a session share one timestamp.
        #expect(timestamp(of: urls[0]) == timestamp(of: urls[1]))
    }

    @Test("An oversized first write is split across bounded files")
    func splitsOversizedFirstWriteAcrossFiles() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)

        await sut.write(Data(repeating: 0x61, count: 100))
        let urls = await sut.fileURLs()

        #expect(urls.count == 5)
        #expect(urls.allSatisfy { fileSize(of: $0) <= 10 })
    }

    @Test("An oversized write after a full file is split across bounded files")
    func splitsOversizedWriteAfterFullFile() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)

        await sut.write(Data(repeating: 0x61, count: 10))
        await sut.write(Data(repeating: 0x62, count: 25))
        let urls = await sut.fileURLs()

        #expect(urls.count == 4)
        #expect(urls.map { fileSize(of: $0) } == [10, 10, 10, 5])
    }

    @Test("The set never grows beyond the maximum number of files")
    func neverExceedsMaxFileCount() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)

        for index in 0..<12 {
            await sut.write(Data("0123456789".utf8))
            await sut.write(Data("\(index)".utf8))
        }
        let urls = await sut.fileURLs()

        #expect(urls.count == 5)
    }

    @Test("Once the last file is reached the oldest one is cleared and reused")
    func wrapsAroundClearingTheOldestFile() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)

        // Fills files 1 to 5, then wraps back onto file 1.
        for index in 1...5 {
            await sut.write(Data("file-\(index)-x".utf8))
        }
        await sut.write(Data("wrapped".utf8))
        let urls = await sut.fileURLs()

        #expect(urls.count == 5)
        #expect(contents(of: urls[0]) == "wrapped")
        #expect(contents(of: urls[1]) == "file-2-x")
    }

    @Test("A relaunch keeps appending to the file that was written last")
    func resumesTheExistingSessionAfterRelaunch() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let first = makeSUT(directory: directory)
        await first.write(Data("0123456789".utf8))
        await first.write(Data("second".utf8))

        let second = makeSUT(directory: directory)
        await second.write(Data("!".utf8))
        let urls = await second.fileURLs()

        #expect(urls.count == 2)
        #expect(contents(of: urls[0]) == "0123456789")
        #expect(contents(of: urls[1]) == "second!")
    }

    // MARK: - Clean-up

    @Test("Clearing removes every managed file and starts a new session")
    func clearRemovesManagedFiles() async {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)
        await sut.write(Data("0123456789".utf8))
        await sut.write(Data("second".utf8))

        await sut.clear()
        let clearedURLs = await sut.fileURLs()
        #expect(clearedURLs.isEmpty)

        await sut.write(Data("fresh".utf8))
        let urls = await sut.fileURLs()

        #expect(urls.count == 1)
        #expect(contents(of: urls[0]) == "fresh")
    }

    @Test("Clearing leaves unmanaged files in the directory untouched")
    func clearKeepsUnmanagedFiles() async throws {
        let directory = makeDirectory()
        defer { cleanup(directory) }
        let sut = makeSUT(directory: directory)
        await sut.write(Data("hello".utf8))
        let other = directory.appendingPathComponent("readme.txt")
        try Data("keep".utf8).write(to: other)

        await sut.clear()
        let clearedURLs = await sut.fileURLs()

        #expect(clearedURLs.isEmpty)
        #expect(FileManager.default.fileExists(atPath: other.path))
    }

    private func timestamp(of url: URL) -> String {
        let name = url.lastPathComponent
        guard let range = name.range(of: RotatingLogFileSet.fileNameSeparator, options: .backwards) else {
            return name
        }
        return String(name[name.startIndex..<range.lowerBound])
    }
}
