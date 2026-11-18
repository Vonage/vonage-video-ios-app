//
//  Created by Vonage on 18/10/26.
//

import Foundation
import Testing
import VERAArchiving

@Suite("URLSession archive file downloader tests", .serialized)
struct URLSessionArchiveFileDownloaderTests {

    @Test("Saves the downloaded file under the requested name")
    func savesFileUnderRequestedName() async throws {
        let body = Data("transcript".utf8)
        StubURLProtocol.response = (200, body)
        let sut = makeSUT()

        let fileURL = try await sut.download(
            from: URL(string: "https://example.com/transcript.zip")!,
            fileName: "transcription-1.zip")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        #expect(fileURL.lastPathComponent == "transcription-1.zip")
        #expect(try Data(contentsOf: fileURL) == body)
    }

    @Test("Replaces an earlier download with the same name")
    func replacesEarlierDownloadWithSameName() async throws {
        let sut = makeSUT()
        let url = URL(string: "https://example.com/transcript.zip")!

        StubURLProtocol.response = (200, Data("first".utf8))
        _ = try await sut.download(from: url, fileName: "transcription-replace.zip")
        StubURLProtocol.response = (200, Data("second".utf8))
        let fileURL = try await sut.download(from: url, fileName: "transcription-replace.zip")
        defer { try? FileManager.default.removeItem(at: fileURL) }

        #expect(try Data(contentsOf: fileURL) == Data("second".utf8))
    }

    @Test("Throws for unsuccessful HTTP responses")
    func throwsForUnsuccessfulResponses() async {
        StubURLProtocol.response = (403, Data())
        let sut = makeSUT()

        await #expect(throws: URLSessionArchiveFileDownloader.Error.self) {
            try await sut.download(
                from: URL(string: "https://example.com/expired.zip")!,
                fileName: "transcription.zip")
        }
    }

    // MARK: - Test Helpers

    private func makeSUT() -> URLSessionArchiveFileDownloader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSessionArchiveFileDownloader(session: URLSession(configuration: configuration))
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var response: (statusCode: Int, body: Data) = (200, Data())

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (statusCode, body) = Self.response
        guard
            let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
