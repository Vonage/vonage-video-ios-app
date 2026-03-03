//
//  Created by Vonage on 26/2/26.
//

import Testing
import VERAScreenShare

@testable import VERAVonageScreenSharePlugin

@Suite("VonageScreenSharePlugin Tests")
struct VonageScreenSharePluginTests {

    @Test("callDidStart saves credentials from userInfo")
    func callDidStartSavesCredentials() async throws {
        let repository = InMemoryScreenShareCredentialsRepository()
        let plugin = VonageScreenSharePlugin(credentialsRepository: repository)

        let userInfo: [String: Any] = [
            "applicationId": "app-123",
            "sessionId": "session-abc",
            "token": "token-xyz",
        ]

        try await plugin.callDidStart(userInfo)

        let saved = repository.saved
        #expect(saved?.applicationId == "app-123")
        #expect(saved?.sessionId == "session-abc")
        #expect(saved?.token == "token-xyz")
    }

    @Test("callDidEnd clears stored credentials")
    func callDidEndClearsCredentials() async throws {
        let repository = InMemoryScreenShareCredentialsRepository()
        repository.saved = ScreenShareCredentials(
            applicationId: "app-123",
            sessionId: "session-abc",
            token: "token-xyz")

        let plugin = VonageScreenSharePlugin(credentialsRepository: repository)
        try await plugin.callDidEnd()

        #expect(repository.saved == nil)
    }

    @Test("callDidStart with missing keys does not save credentials")
    func callDidStartWithMissingKeysDoesNotSave() async throws {
        let repository = InMemoryScreenShareCredentialsRepository()
        let plugin = VonageScreenSharePlugin(credentialsRepository: repository)

        try await plugin.callDidStart([:])

        #expect(repository.saved == nil)
    }
}

// MARK: - Test Helpers

private final class InMemoryScreenShareCredentialsRepository: ScreenShareCredentialsRepository {
    var saved: ScreenShareCredentials?

    func save(_ credentials: ScreenShareCredentials) {
        saved = credentials
    }

    func clear() {
        saved = nil
    }
}
