//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERADomain

@Suite("Session event value transfer")
struct SessionEventTransferTests {

    @Test("Session events preserve cases, identifiers and error payloads across tasks")
    func eventsAcrossTasks() async {
        let swiftError = FixtureFailure.failed("fixture-message")
        let cocoaError = NSError(
            domain: "fixture-domain", code: 42, userInfo: [NSLocalizedDescriptionKey: "fixture-error"])
        let events: [SessionEvent] = [
            .idle, .connected, .disconnected, .didBeginReconnecting, .didReconnect,
            .streamReceived(streamId: "received-id"), .streamDropped(streamId: "dropped-id"), .muteForced,
            .error(swiftError), .sessionFailure(swiftError), .error(cocoaError),
            .sessionFailure(cocoaError),
        ]

        for event in events {
            let received = await Task.detached { event }.value
            switch (event, received) {
            case (.idle, .idle), (.connected, .connected), (.disconnected, .disconnected),
                (.didBeginReconnecting, .didBeginReconnecting), (.didReconnect, .didReconnect),
                (.muteForced, .muteForced):
                break
            case (.streamReceived(let expected), .streamReceived(let actual)),
                (.streamDropped(let expected), .streamDropped(let actual)):
                #expect(actual == expected)
            case (.error(let expected), .error(let actual)),
                (.sessionFailure(let expected), .sessionFailure(let actual)):
                if let expected = expected as? FixtureFailure {
                    #expect(actual as? FixtureFailure == expected)
                } else {
                    let expected = expected as NSError
                    let actual = actual as NSError
                    #expect(actual.domain == expected.domain)
                    #expect(actual.code == expected.code)
                    #expect(actual.localizedDescription == expected.localizedDescription)
                }
            default:
                Issue.record("Session event changed during task transfer")
            }
        }
    }
}

private enum FixtureFailure: Error, Equatable {
    case failed(String)
}
