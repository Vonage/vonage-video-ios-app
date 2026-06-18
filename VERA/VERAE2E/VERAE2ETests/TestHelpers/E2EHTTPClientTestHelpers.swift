//
//  Created by Vonage on 7/6/26.
//

import Foundation
import Testing
import VERACore

@testable import VERAE2E

let e2EBaseURL = URL(string: "https://meet.example.com/v2")!

func postJSON(
    _ sut: E2EHTTPClient,
    endpoint: E2EEndpoint,
    body: [String: Any]
) async throws -> [String: Any] {
    let data = try await sut.post(
        e2EBaseURL.appendingPathComponent(endpoint.rawValue),
        data: try JSONSerialization.data(withJSONObject: body))

    let json = try #require(
        try JSONSerialization.jsonObject(with: data) as? [String: Any])
    let result = try #require(json["result"] as? [String: Any])
    return try #require(result["data"] as? [String: Any])
}

final class HTTPClientInterceptorSpy: HTTPClientInterceptor, @unchecked Sendable {
    private(set) var successEvents: [HTTPClientSuccessEvent] = []
    private(set) var failureEvents: [HTTPClientFailureEvent] = []

    func didSucceed(_ event: HTTPClientSuccessEvent) {
        successEvents.append(event)
    }

    func didFail(_ event: HTTPClientFailureEvent) {
        failureEvents.append(event)
    }
}
