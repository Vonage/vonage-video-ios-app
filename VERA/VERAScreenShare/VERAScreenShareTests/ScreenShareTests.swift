//
//  Created by Vonage on 26/2/26.
//

import Testing

@testable import VERAScreenShare

@Suite("ScreenShare Tests")
struct ScreenShareTests {

    @Test("ScreenShareCredentials stores correct values")
    func credentialsStoreValues() {
        let credentials = ScreenShareCredentials(
            applicationId: "app-123",
            sessionId: "session-abc",
            token: "token-xyz")

        #expect(credentials.applicationId == "app-123")
        #expect(credentials.sessionId == "session-abc")
        #expect(credentials.token == "token-xyz")
    }

    @Test("ScreenShareCredentialsUseCase saves and clears through repository")
    func saveAndClearCredentials() {
        let repository = InMemoryScreenShareCredentialsRepository()
        let useCase = ScreenShareCredentialsUseCase(repository: repository)

        let credentials = ScreenShareCredentials(
            applicationId: "app-123",
            sessionId: "session-abc",
            token: "token-xyz")

        useCase.saveCredentials(credentials)
        #expect(repository.saved == credentials)

        useCase.clearCredentials()
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
