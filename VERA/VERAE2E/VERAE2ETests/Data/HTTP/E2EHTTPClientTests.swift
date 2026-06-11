//
//  Created by Vonage on 7/6/26.
//

import Foundation
import Testing
import VERACore

@testable import VERAE2E

@Suite("E2E HTTP client tests", .serialized)
struct E2EHTTPClientTests {

    @Test("Unknown GET endpoint throws and logs not found")
    func unknownGETEndpointThrowsAndLogsNotFound() async throws {
        let interceptor = HTTPClientInterceptorSpy()
        let sut = E2EHTTPClient(store: E2EBackendStore(), interceptor: interceptor)

        await #expect(throws: HTTPClientError.httpError(statusCode: 404)) {
            _ = try await sut.get(e2EBaseURL.appendingPathComponent("unknownEndpoint"))
        }

        let failure = try #require(interceptor.failureEvents.last)
        #expect(failure.statusCode == 404)
        #expect(failure.url?.lastPathComponent == "unknownEndpoint")
    }

    @Test("Configured failure endpoint throws and logs failure", arguments: E2EEndpoint.allCases)
    func configuredFailureEndpointThrows(endpoint: E2EEndpoint) async throws {
        UserDefaults.standard.set(endpoint.rawValue, forKey: E2EConfiguration.failEndpointArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.failEndpointArgument) }

        let interceptor = HTTPClientInterceptorSpy()
        let sut = E2EHTTPClient(store: E2EBackendStore(), interceptor: interceptor)

        await #expect(throws: HTTPClientError.httpError(statusCode: 500)) {
            _ = try await sut.post(
                e2EBaseURL.appendingPathComponent(endpoint.rawValue),
                data: try JSONSerialization.data(
                    withJSONObject: [
                        "roomName": "testroom",
                        "sessionKey": "e2e-session-key",
                        "archiveId": UUID().uuidString.lowercased(),
                    ]))
        }

        let failure = try #require(interceptor.failureEvents.last)
        #expect(failure.statusCode == 500)
        #expect(failure.url?.lastPathComponent == endpoint.rawValue)
        #expect(failure.responseBodyPreview?.contains("VERA_E2E_FORCED_FAILURE") == true)
    }
}
