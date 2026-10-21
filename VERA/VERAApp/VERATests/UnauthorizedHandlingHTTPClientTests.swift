//
//  Created by Vonage on 24/9/26.
//

import Foundation
import Testing
import VERACore
import VERADomain

@testable import VERA

@Suite("UnauthorizedHandlingHTTPClient tests")
struct UnauthorizedHandlingHTTPClientTests {

    let url = URL(string: "https://video.vonage.com/v2/createSession")!

    @Test("On 401, the handler is invoked and UnauthorizedError is rethrown")
    func on401TriggersHandlerAndRethrowsUnauthorized() async {
        let stub = StubHTTPClient(result: .failure(HTTPClientError.httpError(statusCode: 401)))
        let handler = HandlerSpy()
        let sut = UnauthorizedHandlingHTTPClient(wrapped: stub) { await handler.record() }

        await #expect(throws: UnauthorizedError.self) {
            _ = try await sut.get(url)
        }
        #expect(await handler.count == 1)
    }

    @Test("On a non-401 error, the handler is not invoked and the original error is rethrown")
    func onOtherErrorDoesNotTriggerHandler() async {
        let stub = StubHTTPClient(result: .failure(HTTPClientError.httpError(statusCode: 500)))
        let handler = HandlerSpy()
        let sut = UnauthorizedHandlingHTTPClient(wrapped: stub) { await handler.record() }

        await #expect(throws: HTTPClientError.self) {
            _ = try await sut.post(url, data: Data())
        }
        #expect(await handler.count == 0)
    }

    @Test("On success, data is returned and the handler is not invoked")
    func onSuccessReturnsDataWithoutHandler() async throws {
        let expected = Data("ok".utf8)
        let stub = StubHTTPClient(result: .success(expected))
        let handler = HandlerSpy()
        let sut = UnauthorizedHandlingHTTPClient(wrapped: stub) { await handler.record() }

        let data = try await sut.get(url)

        #expect(data == expected)
        #expect(await handler.count == 0)
    }
}

private struct StubHTTPClient: HTTPClient {
    let result: Result<Data, Error>

    func get(_ url: URL, additionalHeaders: [String: String]) async throws -> Data {
        try result.get()
    }

    func post(_ url: URL, additionalHeaders: [String: String], data: Data) async throws -> Data {
        try result.get()
    }
}

private actor HandlerSpy {
    private(set) var count = 0
    func record() { count += 1 }
}
