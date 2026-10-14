//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERAScreenShare

@Suite("Screen sharing credentials value transfer")
struct ScreenShareCredentialsTransferTests {

    @Test("All credential fields survive task and actor round trips")
    func credentialsAcrossTasksAndActor() async {
        let credentials = [
            ScreenShareCredentials(applicationId: "", sessionId: "", token: "", username: ""),
            ScreenShareCredentials(
                applicationId: "synthetic-app", sessionId: "synthetic-session",
                token: "synthetic-token", username: "synthetic-user"),
            ScreenShareCredentials(
                applicationId: "application-é", sessionId: "session-東京",
                token: "synthetic-🔑", username: "participant-👩🏽‍💻"),
        ]
        let transferred = await Task.detached { credentials }.value
        #expect(transferred == credentials)

        let storage = ScreenShareCredentialsStorage()
        for expected in transferred {
            await storage.store(expected)
            let received = await storage.credentials
            #expect(received == expected)
            #expect(received?.applicationId == expected.applicationId)
            #expect(received?.sessionId == expected.sessionId)
            #expect(received?.token == expected.token)
            #expect(received?.username == expected.username)
        }
    }

    @Test("Replacing actor storage preserves an earlier credential snapshot")
    func independentSnapshots() async {
        let initial = ScreenShareCredentials(
            applicationId: "synthetic-app-1", sessionId: "synthetic-session-1",
            token: "synthetic-token-1", username: "synthetic-user-1")
        let replacement = ScreenShareCredentials(
            applicationId: "synthetic-app-2", sessionId: "synthetic-session-2",
            token: "synthetic-token-2", username: "synthetic-user-2")
        let storage = ScreenShareCredentialsStorage()
        await storage.store(initial)
        let snapshot = await storage.credentials
        await storage.store(replacement)
        let latest = await storage.credentials
        #expect(snapshot == initial)
        #expect(latest == replacement)
        #expect(snapshot != latest)
    }
}

private actor ScreenShareCredentialsStorage {
    private(set) var credentials: ScreenShareCredentials?

    func store(_ value: ScreenShareCredentials) {
        credentials = value
    }
}
