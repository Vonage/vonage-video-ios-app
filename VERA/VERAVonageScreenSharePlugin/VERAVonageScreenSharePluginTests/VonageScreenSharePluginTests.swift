//
//  Created by Vonage on 26/2/26.
//

import Testing
import VERAScreenShare
import os

@testable import VERAVonageScreenSharePlugin

@Suite("VonageScreenSharePlugin Tests", .serialized)
struct VonageScreenSharePluginTests {

    @Test("callDidStart saves credentials from userInfo")
    func callDidStartSavesCredentials() async throws {
        let repository = InMemoryScreenShareCredentialsRepository()
        let plugin = makeSUT(repository: repository)

        let userInfo: [String: Any] = [
            "applicationId": "app-123",
            "sessionId": "session-abc",
            "token": "token-xyz",
            "username": "a-username",
        ]

        try await plugin.callDidStart(userInfo)

        let saved = repository.saved
        #expect(saved?.applicationId == "app-123")
        #expect(saved?.sessionId == "session-abc")
        #expect(saved?.token == "token-xyz")
        #expect(saved?.username == "a-username")
    }

    @Test("callDidEnd clears stored credentials")
    func callDidEndClearsCredentials() async throws {
        let repository = InMemoryScreenShareCredentialsRepository()
        repository.saved = ScreenShareCredentials(
            applicationId: "app-123",
            sessionId: "session-abc",
            token: "token-xyz",
            username: "a-username")

        let plugin = makeSUT(repository: repository)
        try await plugin.callDidEnd()

        #expect(repository.saved == nil)
    }

    @Test("callDidStart with missing keys does not save credentials")
    func callDidStartWithMissingKeysDoesNotSave() async throws {
        let repository = InMemoryScreenShareCredentialsRepository()
        let plugin = makeSUT(repository: repository)

        try await plugin.callDidStart([:])

        #expect(repository.saved == nil)
    }

    @Test("callDidStart installs the system picker hook only when capture is available")
    func callDidStartPickerHookMatchesAvailability() async throws {
        await MainActor.run { ScreenShareUIBridge.shared.presentSystemPicker = nil }
        let repository = InMemoryScreenShareCredentialsRepository()
        let plugin = makeSUT(repository: repository)

        try await plugin.callDidStart([
            "applicationId": "app-123",
            "sessionId": "session-abc",
            "token": "token-xyz",
            "username": "a-username",
        ])

        let installed = await MainActor.run { ScreenShareUIBridge.shared.presentSystemPicker != nil }
        #expect(installed == ScreenShareAvailability.usesSystemContentPicker)

        try await plugin.callDidEnd()
        let cleared = await MainActor.run { ScreenShareUIBridge.shared.presentSystemPicker == nil }
        #expect(cleared)
    }

    @Test("callDidStart activates an injected capturer and the button presents it")
    func callDidStartActivatesInjectedCapturer() async throws {
        await MainActor.run { ScreenShareUIBridge.shared.presentSystemPicker = nil }
        let controller = CaptureControllerSpy()
        let plugin = VonageScreenSharePlugin(
            credentialsRepository: InMemoryScreenShareCredentialsRepository(),
            captureController: controller)
        let userInfo: [String: Any] = [
            "applicationId": "app-123",
            "sessionId": "session-abc",
            "token": "token-xyz",
            "username": "a-username",
        ]

        try await plugin.callDidStart(userInfo)
        #expect(controller.activated == 1)
        #expect(controller.consumer != nil)

        await MainActor.run { ScreenShareUIBridge.shared.present() }
        #expect(controller.presented == 1)

        try await plugin.callDidStart(userInfo)
        #expect(controller.activated == 2)

        try await plugin.callDidEnd()
        #expect(controller.deactivated == 1)
        let cleared = await MainActor.run { ScreenShareUIBridge.shared.presentSystemPicker == nil }
        #expect(cleared)
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: ScreenShareCredentialsRepository
    ) -> VonageScreenSharePlugin {
        return VonageScreenSharePlugin(credentialsRepository: repository)
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

private final class CaptureControllerSpy: ScreenCaptureControlling, @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(
        initialState: (activated: 0, deactivated: 0, presented: 0))
    private let consumerLock = OSAllocatedUnfairLock<
        (any ScreenShareFrameConsuming & Sendable)?
    >(initialState: nil)

    var activated: Int { lock.withLock { $0.activated } }
    var deactivated: Int { lock.withLock { $0.deactivated } }
    var presented: Int { lock.withLock { $0.presented } }
    var consumer: (any ScreenShareFrameConsuming & Sendable)? { consumerLock.withLock { $0 } }

    func activate() { lock.withLock { $0.activated += 1 } }
    func deactivate() { lock.withLock { $0.deactivated += 1 } }
    func presentPicker() { lock.withLock { $0.presented += 1 } }
    func setFrameConsumer(_ consumer: (any ScreenShareFrameConsuming & Sendable)?) {
        consumerLock.withLock { $0 = consumer }
    }
}
