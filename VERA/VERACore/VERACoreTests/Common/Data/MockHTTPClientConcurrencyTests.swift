//
//  Created by Vonage on 15/10/2026.
//

import Foundation
import Testing
import VERATestHelpers

@Suite("Concurrent HTTP test double")
struct MockHTTPClientConcurrencyTests {
    @Test("Each overlapping request retains its own configured response and records once")
    func overlappingRequestsKeepDistinctResponses() async throws {
        let count = 24
        let responses = (0..<count).map { Data("response-\($0)".utf8) }
        let client = MockHTTPClient(delaySeconds: 0.01)
        client.dataSequence = responses
        let url = try #require(URL(string: "https://example.test/requests"))

        let received = try await withThrowingTaskGroup(of: Data.self) { group in
            for index in 0..<count {
                group.addTask {
                    try await client.post(url, data: Data("request-\(index)".utf8))
                }
            }
            var received: [Data] = []
            for try await response in group {
                received.append(response)
            }
            return received
        }

        #expect(Set(received) == Set(responses))
        #expect(client.callCount == count)
        #expect(client.recordedURLs == Array(repeating: url, count: count))
        #expect(Set(client.recordedDataSequence) == Set((0..<count).map { Data("request-\($0)".utf8) }))
    }
}
