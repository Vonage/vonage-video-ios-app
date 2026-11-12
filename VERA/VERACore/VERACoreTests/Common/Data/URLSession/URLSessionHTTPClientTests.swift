//
//  Created by Vonage on 15/1/26.
//

import Foundation
import Testing
import VERACore
import VERADomain

@testable import VERATestHelpers

@Suite("URL Session HTTP client tests", .serialized)
final class URLSessionHTTPClientTests {

    // MARK: - GET Tests

    @Test
    func get_requestsDataFromURL() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, spy) = makeSUT()

        spy.stub(url: url, statusCode: 200, data: Data())
        _ = try? await sut.get(url)

        #expect(spy.requestedURLs == [url])
    }

    @Test
    func get_requestsDataFromURLTwice() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, spy) = makeSUT()

        spy.stub(url: url, statusCode: 200, data: Data())
        _ = try? await sut.get(url)
        _ = try? await sut.get(url)

        #expect(spy.requestedURLs == [url, url])
    }

    @Test
    func get_deliversInvalidResponseErrorOnNonHTTPResponse() async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, spy) = makeSUT(interceptor: interceptor)

        let response = URLResponse(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil)
        spy.stub(url: url, response: response, data: Data())

        await #expect(
            performing: {
                try await sut.get(url)
            },
            throws: { error in
                guard let httpError = error as? HTTPClientError else { return false }
                return httpError == .invalidResponse
            })

        #expect(
            interceptor.events == [
                HTTPClientFailureEvent(
                    method: "GET",
                    url: url,
                    statusCode: nil,
                    requestBodyPreview: nil,
                    responseBodyPreview: nil,
                    errorDescription: String(describing: HTTPClientError.invalidResponse))
            ])
    }

    @Test(arguments: [199, 300, 400, 500])
    func get_deliversHTTPErrorOnNon2xxStatusCode(statusCode: Int) async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, spy) = makeSUT(interceptor: interceptor)
        let responseBody = Data("{\"error\":\"something went wrong\"}".utf8)
        spy.stub(url: url, statusCode: statusCode, data: responseBody)

        await #expect(
            performing: {
                try await sut.get(url)
            },
            throws: { error in
                guard let httpError = error as? HTTPClientError,
                    case .httpError(let receivedStatusCode) = httpError
                else {
                    return false
                }
                return receivedStatusCode == statusCode
            })

        #expect(
            interceptor.events == [
                HTTPClientFailureEvent(
                    method: "GET",
                    url: url,
                    statusCode: statusCode,
                    requestBodyPreview: nil,
                    responseBodyPreview: String(data: responseBody, encoding: .utf8),
                    errorDescription: String(describing: HTTPClientError.httpError(statusCode: statusCode)))
            ])
    }

    @Test
    func get_deliversNetworkErrorAndLogsFailureEvent() async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, _) = makeSUT(interceptor: interceptor)

        await #expect(
            performing: {
                try await sut.get(url)
            },
            throws: { _ in true })

        let event = try #require(interceptor.events.first)
        #expect(interceptor.events.count == 1)
        #expect(event.method == "GET")
        #expect(event.url == url)
        #expect(event.statusCode == nil)
        #expect(event.requestBodyPreview == nil)
        #expect(event.responseBodyPreview == nil)
        #expect(event.errorDescription.isEmpty == false)
    }

    @Test
    func get_deliversDataOn200HTTPResponse() async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, spy) = makeSUT(interceptor: interceptor)
        let expectedData = Data("any data".utf8)

        spy.stub(url: url, statusCode: 200, data: expectedData)

        let receivedData = try await sut.get(url)

        #expect(receivedData == expectedData)
        #expect(
            interceptor.successEvents == [
                HTTPClientSuccessEvent(
                    method: "GET",
                    url: url,
                    statusCode: 200,
                    requestBodyPreview: nil,
                    responseBodyPreview: "any data")
            ])
    }

    @Test(arguments: [200, 201, 250, 280, 299])
    func get_deliversDataOn2xxHTTPResponse(statusCode: Int) async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        let expectedData = Data("any data".utf8)

        spy.stub(url: url, statusCode: statusCode, data: expectedData)

        let receivedData = try await sut.get(url)

        #expect(receivedData == expectedData)
    }

    // MARK: - POST Tests

    @Test
    func post_requestsDataFromURLWithBody() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let requestBody = Data("request body".utf8)
        let (sut, spy) = makeSUT()

        spy.stub(url: url, statusCode: 200, data: Data())
        _ = try? await sut.post(url, data: requestBody)

        #expect(spy.requestedURLs == [url])
        #expect(spy.requestedBodies == [requestBody])
    }

    @Test
    func post_setsContentTypeAndAcceptHeaders() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let requestBody = Data("request body".utf8)
        let (sut, spy) = makeSUT()

        spy.stub(url: url, statusCode: 200, data: Data())
        _ = try? await sut.post(url, data: requestBody)

        guard let request = spy.requestedRequests.first else {
            Issue.record("Expected at least one request")
            return
        }

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test
    func post_withAdditionalHeaders_mergesHeadersIntoRequest() async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        let requestBody = Data("request".utf8)
        let expectedData = Data("ok".utf8)

        spy.stub(url: url, statusCode: 200, data: expectedData)

        let receivedData = try await sut.post(
            url,
            additionalHeaders: ["User-Agent": "VeraNativeiOS/1.0"],
            data: requestBody
        )

        let request = try #require(spy.requestedRequests.last)
        #expect(receivedData == expectedData)
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "VeraNativeiOS/1.0")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test
    func post_throughHTTPClientProtocol_usesEmptyAdditionalHeaders() async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        let expectedData = Data("ok".utf8)

        spy.stub(url: url, statusCode: 200, data: expectedData)

        let client: HTTPClient = sut
        let receivedData = try await client.post(url, data: Data("request".utf8))

        let request = try #require(spy.requestedRequests.last)
        #expect(receivedData == expectedData)
        #expect(request.value(forHTTPHeaderField: "User-Agent") == nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func post_usesHTTPMethodPOST() async throws {
        let url = URL(string: "https://a-given-url.com")!
        let requestBody = Data("request body".utf8)
        let (sut, spy) = makeSUT()

        spy.stub(url: url, statusCode: 200, data: Data())
        _ = try? await sut.post(url, data: requestBody)

        guard let request = spy.requestedRequests.first else {
            Issue.record("Expected at least one request")
            return
        }

        #expect(request.httpMethod == "POST")
    }

    @Test
    func post_deliversInvalidResponseErrorOnNonHTTPResponse() async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, spy) = makeSUT(interceptor: interceptor)

        let response = URLResponse(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil)

        spy.stub(
            url: url,
            response: response,
            data: Data())

        await #expect(
            performing: {
                try await sut.post(url, data: Data())
            },
            throws: { error in
                guard let httpError = error as? HTTPClientError else { return false }
                return httpError == .invalidResponse
            })

        #expect(
            interceptor.events == [
                HTTPClientFailureEvent(
                    method: "POST",
                    url: url,
                    statusCode: nil,
                    requestBodyPreview: nil,
                    responseBodyPreview: nil,
                    errorDescription: String(describing: HTTPClientError.invalidResponse))
            ])
    }

    @Test(arguments: [199, 300, 400, 500])
    func post_deliversHTTPErrorOnNon2xxStatusCode(statusCode: Int) async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, spy) = makeSUT(interceptor: interceptor)
        let requestBody = Data("{\"archiveId\":\"archive-1\",\"sessionKey\":\"secret-session-key\"}".utf8)
        let responseBody = Data("{\"error\":\"something went wrong\"}".utf8)
        spy.stub(url: url, statusCode: statusCode, data: responseBody)

        await #expect(
            performing: {
                try await sut.post(url, data: requestBody)
            },
            throws: { error in
                guard let httpError = error as? HTTPClientError,
                    case .httpError(let receivedStatusCode) = httpError
                else {
                    return false
                }
                return receivedStatusCode == statusCode
            })

        #expect(
            interceptor.events == [
                HTTPClientFailureEvent(
                    method: "POST",
                    url: url,
                    statusCode: statusCode,
                    requestBodyPreview: "{\"archiveId\":\"archive-1\",\"sessionKey\":\"<redacted>\"}",
                    responseBodyPreview: String(data: responseBody, encoding: .utf8),
                    errorDescription: String(describing: HTTPClientError.httpError(statusCode: statusCode)))
            ])
    }

    @Test
    func post_deliversDataOn200HTTPResponse() async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, spy) = makeSUT(interceptor: interceptor)
        let requestBody = Data(
            """
            {"roomName":"testroom","sessionKey":"secret-session-key","archiveId":"archive-1"}
            """.utf8)
        let expectedData = Data(
            (#"{"result":{"data":{"applicationId":"secret-app","count":1,"items":["#
                + #"{"id":"archive-1","status":"available","token":"secret-token"}]}}}"#).utf8)
        let expectedRequestBodyPreview =
            #"{"archiveId":"archive-1","roomName":"testroom","sessionKey":"<redacted>"}"#
        let expectedResponseBodyPreview =
            #"{"result":{"data":{"applicationId":"<redacted>","count":1,"items":["#
            + #"{"id":"archive-1","status":"available","token":"<redacted>"}]}}}"#

        spy.stub(url: url, statusCode: 200, data: expectedData)

        let receivedData = try await sut.post(url, data: requestBody)

        #expect(receivedData == expectedData)
        #expect(
            interceptor.successEvents == [
                HTTPClientSuccessEvent(
                    method: "POST",
                    url: url,
                    statusCode: 200,
                    requestBodyPreview: expectedRequestBodyPreview,
                    responseBodyPreview: expectedResponseBodyPreview)
            ])
    }

    @Test
    func post_truncatesSanitizedBodyPreviews() async throws {
        let url = URL(string: "https://a-url.com")!
        let interceptor = HTTPClientInterceptorSpy()
        let (sut, spy) = makeSUT(interceptor: interceptor)
        let longRoomName = String(repeating: "a", count: 3_000)
        let requestBody = Data(
            """
            {"apiKey":"secret-api-key","roomName":"\(longRoomName)","sessionKey":"secret-session-key"}
            """.utf8)
        let responseBody = Data(
            """
            {"apiKey":"secret-api-key","count":1,"status":"available","token":"secret-token","message":"\(longRoomName)"}
            """.utf8)

        spy.stub(url: url, statusCode: 200, data: responseBody)

        _ = try await sut.post(url, data: requestBody)

        let successEvent = try #require(interceptor.successEvents.first)
        #expect(successEvent.requestBodyPreview?.contains("\"apiKey\":\"<redacted>\"") == true)
        #expect(successEvent.requestBodyPreview?.contains("secret-api-key") == false)
        #expect(successEvent.requestBodyPreview?.contains("secret-session-key") == false)
        #expect(successEvent.requestBodyPreview?.hasSuffix("... <truncated>") == true)
        #expect(successEvent.responseBodyPreview?.contains("\"apiKey\":\"<redacted>\"") == true)
        #expect(successEvent.responseBodyPreview?.contains("secret-api-key") == false)
        #expect(successEvent.responseBodyPreview?.contains("secret-token") == false)
        #expect(successEvent.responseBodyPreview?.hasSuffix("... <truncated>") == true)
    }

    @Test(arguments: [200, 201, 250, 280, 299])
    func post_deliversDataOn2xxHTTPResponse(statusCode: Int) async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        let expectedData = Data("response data".utf8)

        spy.stub(url: url, statusCode: statusCode, data: expectedData)

        let receivedData = try await sut.post(url, data: Data("request".utf8))

        #expect(receivedData == expectedData)
    }

    // MARK: - Helpers

    private func makeSUT(
        interceptor: any HTTPClientInterceptor = HTTPClientInterceptorSpy(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: URLSessionHTTPClient, spy: URLSessionHTTPClientSpy) {
        let spy = URLSessionHTTPClientSpy()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session, interceptor: interceptor)

        URLProtocolStub.stub = spy

        return (sut, spy)
    }

    // MARK: - Spy

    private final class URLSessionHTTPClientSpy: Sendable {
        private struct State: Sendable {
            var requestedURLs: [URL] = []
            var requestedBodies: [Data] = []
            var requestedRequests: [URLRequest] = []
            var stubs: [URL: Stub] = [:]
        }
        private let state = TestLockedValue(State())
        var requestedURLs: [URL] { state.withValue { $0.requestedURLs } }
        var requestedBodies: [Data] { state.withValue { $0.requestedBodies } }
        var requestedRequests: [URLRequest] { state.withValue { $0.requestedRequests } }

        struct Stub: Sendable {
            let response: URLResponse
            let data: Data
        }

        func stub(url: URL, response: URLResponse, data: Data) {
            state.withValue { $0.stubs[url] = Stub(response: response, data: data) }
        }

        func stub(url: URL, statusCode: Int, data: Data) {
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil)!
            stub(url: url, response: response, data: data)
        }

        func record(_ request: URLRequest) {
            // Consume a request's stream outside the observation lock.
            let body: Data
            if let data = request.httpBody {
                body = data
            } else if let stream = request.httpBodyStream {
                body = data(from: stream)
            } else {
                body = Data()
            }
            state.withValue {
                if let url = request.url { $0.requestedURLs.append(url) }
                $0.requestedRequests.append(request)
                $0.requestedBodies.append(body)
            }
        }

        func response(for url: URL) -> Stub? {
            state.withValue { $0.stubs[url] }
        }

        private func data(from stream: InputStream) -> Data {
            var data = Data()
            stream.open()
            defer { stream.close() }

            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }

            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                }
            }

            return data
        }
    }

    private final class URLProtocolStub: URLProtocol {
        // This suite serializes the lifetime of its per-test registration; URLSession's
        // callbacks and assertions still access observations through synchronized storage.
        private static let storage = TestLockedValue<URLSessionHTTPClientSpy?>(nil)
        static var stub: URLSessionHTTPClientSpy? {
            get { storage.withValue { $0 } }
            set { storage.withValue { $0 = newValue } }
        }

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: NSError(domain: "URLProtocolStub", code: 0))
                return
            }

            URLProtocolStub.stub?.record(request)

            guard let stubResponse = URLProtocolStub.stub?.response(for: url) else {
                client?.urlProtocol(self, didFailWithError: NSError(domain: "URLProtocolStub", code: 0))
                return
            }

            client?.urlProtocol(self, didReceive: stubResponse.response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stubResponse.data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    private final class HTTPClientInterceptorSpy: HTTPClientInterceptor {
        private struct State: Sendable {
            var successEvents: [HTTPClientSuccessEvent] = []
            var events: [HTTPClientFailureEvent] = []
        }
        private let state = TestLockedValue(State())
        var successEvents: [HTTPClientSuccessEvent] { state.withValue { $0.successEvents } }
        var events: [HTTPClientFailureEvent] { state.withValue { $0.events } }

        func didSucceed(_ event: HTTPClientSuccessEvent) {
            state.withValue { $0.successEvents.append(event) }
        }

        func didFail(_ event: HTTPClientFailureEvent) {
            state.withValue { $0.events.append(event) }
        }
    }
}
