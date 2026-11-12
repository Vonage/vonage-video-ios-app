//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERACaptions

@Suite("Caption activation value transfer")
struct CaptionsActivationTransferTests {

    @Test("Request session keys survive task and actor round trips")
    func requestsAcrossTasksAndActor() async {
        let sessionKeys = ["", "session-key", "réunion-東京-🎥"]
        let requests = sessionKeys.map { EnableCaptionsDataSourceRequest(sessionKey: $0) }
        let transferred = await Task.detached { requests }.value
        #expect(transferred.map(\.sessionKey) == sessionKeys)

        let storage = CaptionsActivationStorage()
        await storage.storeRequests(transferred)
        let received = await storage.requests
        #expect(received.map(\.sessionKey) == sessionKeys)
    }

    @Test("Responses preserve absent, empty, and populated caption IDs across task and actor boundaries")
    func responsesAcrossTasksAndActor() async {
        let captionsIds: [String?] = [nil, "", "captions-123", "sous-titres-東京-🎙️"]
        let responses = captionsIds.map { EnableCaptionsDataSourceResponse(captionsId: $0) }
        let transferred = await Task.detached { responses }.value
        #expect(transferred.map(\.captionsId) == captionsIds)

        let storage = CaptionsActivationStorage()
        await storage.storeResponses(transferred)
        let received = await storage.responses
        #expect(received.map(\.captionsId) == captionsIds)
    }
}

private actor CaptionsActivationStorage {
    private(set) var requests: [EnableCaptionsDataSourceRequest] = []
    private(set) var responses: [EnableCaptionsDataSourceResponse] = []

    func storeRequests(_ values: [EnableCaptionsDataSourceRequest]) {
        requests = values
    }

    func storeResponses(_ values: [EnableCaptionsDataSourceResponse]) {
        responses = values
    }
}
