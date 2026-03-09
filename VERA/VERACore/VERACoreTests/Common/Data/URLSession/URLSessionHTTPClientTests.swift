//
//  Created by Vonage on 15/1/26.
//

import Foundation
import Testing
import VERACore
import VERADomain

@Suite("URL Session HTTP client tests")
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
        let (sut, spy) = makeSUT()

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
    }

    @Test(arguments: [199, 300, 400, 500])
    func get_deliversHTTPErrorOnNon2xxStatusCode(statusCode: Int) async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        spy.stub(url: url, statusCode: statusCode, data: Data())

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
    }

    @Test
    func get_deliversDataOn200HTTPResponse() async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        let expectedData = Data("any data".utf8)

        spy.stub(url: url, statusCode: 200, data: expectedData)

        let receivedData = try await sut.get(url)

        #expect(receivedData == expectedData)
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
        let (sut, spy) = makeSUT()

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
    }

    @Test(arguments: [199, 300, 400, 500])
    func post_deliversHTTPErrorOnNon2xxStatusCode(statusCode: Int) async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        spy.stub(url: url, statusCode: statusCode, data: Data())

        await #expect(
            performing: {
                try await sut.post(url, data: Data())
            },
            throws: { error in
                guard let httpError = error as? HTTPClientError,
                    case .httpError(let receivedStatusCode) = httpError
                else {
                    return false
                }
                return receivedStatusCode == statusCode
            })
    }

    @Test
    func post_deliversDataOn200HTTPResponse() async throws {
        let url = URL(string: "https://a-url.com")!
        let (sut, spy) = makeSUT()
        let expectedData = Data("response data".utf8)

        spy.stub(url: url, statusCode: 200, data: expectedData)

        let receivedData = try await sut.post(url, data: Data("request".utf8))

        #expect(receivedData == expectedData)
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: URLSessionHTTPClient, spy: URLSessionHTTPClientSpy) {
        let spy = URLSessionHTTPClientSpy()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)

        URLProtocolStub.stub = spy

        return (sut, spy)
    }

    // MARK: - Spy

    private final class URLSessionHTTPClientSpy {
        private(set) var requestedURLs: [URL] = []
        private(set) var requestedBodies: [Data] = []
        private(set) var requestedRequests: [URLRequest] = []
        private var stubs: [URL: Stub] = [:]

        struct Stub {
            let response: URLResponse
            let data: Data
        }

        func stub(url: URL, response: URLResponse, data: Data) {
            stubs[url] = Stub(response: response, data: data)
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
            if let url = request.url {
                requestedURLs.append(url)
            }
            requestedRequests.append(request)

            // Extract body from httpBodyStream if httpBody is nil
            if let bodyData = request.httpBody {
                requestedBodies.append(bodyData)
            } else if let stream = request.httpBodyStream {
                requestedBodies.append(data(from: stream))
            } else {
                requestedBodies.append(Data())
            }
        }

        func response(for url: URL) -> Stub? {
            return stubs[url]
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
        static var stub: URLSessionHTTPClientSpy?

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
}
