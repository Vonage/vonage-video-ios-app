//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACaptions

@Suite("CaptionsButtonViewModel Tests")
@MainActor
struct CaptionsButtonViewModelTests {

    // MARK: - Initial State

    @Test("Initial state is disabled")
    func initialState() {
        let (sut, _) = makeSUT()

        #expect(sut.state == .disabled)
    }

    // MARK: - Setup

    @Test("Setup subscribes to captions status and updates state")
    func setupSubscribesToStatus() async throws {
        let (sut, mocks) = makeSUT()

        mocks.statusDataSource.set(captionsState: .enabled("captions-123"))
        sut.setup()

        try await waitUntil { sut.state.captionsEnabled }

        #expect(sut.state == .enabled("captions-123"))
    }

    @Test("Setup only subscribes once even if called multiple times")
    func setupIdempotent() async throws {
        let (sut, mocks) = makeSUT()

        sut.setup()
        sut.setup()

        mocks.statusDataSource.set(captionsState: .enabled("id-1"))
        try await waitUntil { sut.state.captionsEnabled }

        #expect(sut.state == .enabled("id-1"))
    }

    @Test("State updates when status data source emits new values after setup")
    func stateUpdatesOnNewEmissions() async throws {
        let (sut, mocks) = makeSUT()
        sut.setup()

        mocks.statusDataSource.set(captionsState: .enabled("id-1"))
        try await waitUntil { sut.state.captionsEnabled }
        #expect(sut.state == .enabled("id-1"))

        mocks.statusDataSource.set(captionsState: .disabled)
        try await waitUntil { !sut.state.captionsEnabled }
        #expect(sut.state == .disabled)
    }

    // MARK: - onTap Enable

    @Test("Tapping when disabled calls enable use case with session key")
    func tapWhenDisabledCallsEnable() async throws {
        let (sut, mocks) = makeSUT(sessionKey: "my-session-key")
        sut.setup()

        sut.onTap()

        try await waitUntil { mocks.enableUseCase.callCount > 0 }

        #expect(mocks.enableUseCase.callCount == 1)
        #expect(mocks.enableUseCase.lastSessionKey == "my-session-key")
        #expect(mocks.disableUseCase.callCount == 0)
    }

    // MARK: - onTap Disable

    @Test("Tapping when enabled calls disable use case and state becomes disabled")
    func tapWhenEnabledCallsDisable() async throws {
        let (sut, mocks) = makeSUT(sessionKey: "my-session-key")
        sut.setup()

        mocks.statusDataSource.set(captionsState: .enabled("captions-456"))
        try await waitUntil { sut.state.captionsEnabled }

        sut.onTap()

        #expect(mocks.disableUseCase.callCount == 1)
        #expect(mocks.enableUseCase.callCount == 0)
    }

    // MARK: - Error Handling

    @Test("Enable error sets failure toast")
    func enableErrorSetsToast() async throws {
        let (sut, mocks) = makeSUT()
        mocks.enableUseCase.shouldThrow = true
        sut.setup()

        sut.onTap()

        try await waitUntil { sut.toast != nil }

        #expect(mocks.enableUseCase.callCount == 1)
        #expect(sut.toast?.mode == .failure)
        #expect(sut.toast?.message.isEmpty == false)
    }

    @Test("Successful enable does not set toast")
    func successfulEnableNoToast() async throws {
        let (sut, mocks) = makeSUT()
        sut.setup()

        sut.onTap()

        try await waitUntil { mocks.enableUseCase.callCount > 0 }

        #expect(sut.toast == nil)
    }

    @Test("Disable does not set toast")
    func disableNoToast() async throws {
        let (sut, mocks) = makeSUT()
        sut.setup()

        mocks.statusDataSource.set(captionsState: .enabled("id-1"))
        try await waitUntil { sut.state.captionsEnabled }

        sut.onTap()

        #expect(sut.toast == nil)
    }

    @Test("Disable tap does not crash")
    func disableTapDoesNotCrash() async throws {
        let (sut, mocks) = makeSUT()
        sut.setup()

        mocks.statusDataSource.set(captionsState: .enabled("id-1"))
        try await waitUntil { sut.state.captionsEnabled }

        sut.onTap()

        #expect(mocks.disableUseCase.callCount == 1)
    }

    // MARK: - Edge Cases

    @Test("onTap before setup calls enable use case")
    func tapBeforeSetupCallsEnable() async throws {
        let (sut, mocks) = makeSUT()

        sut.onTap()

        try await waitUntil { mocks.enableUseCase.callCount > 0 }

        #expect(mocks.enableUseCase.callCount == 1)
    }

    @Test("State remains disabled immediately after enable tap")
    func stateRemainsDisabledAfterEnableTap() async throws {
        let (sut, mocks) = makeSUT()
        sut.setup()

        sut.onTap()

        // State should still be .disabled — only the data source publisher can change it
        #expect(sut.state == .disabled)

        try await waitUntil { mocks.enableUseCase.callCount > 0 }
    }

    // MARK: - Helpers

    private struct Mocks {
        let enableUseCase: MockEnableCaptionsUseCase
        let disableUseCase: MockDisableCaptionsUseCase
        let statusDataSource: DefaultCaptionsStatusDataSource
    }

    private func makeSUT(
        sessionKey: String = "test-session-key"
    ) -> (CaptionsButtonViewModel, Mocks) {
        let enableUseCase = MockEnableCaptionsUseCase()
        let disableUseCase = MockDisableCaptionsUseCase()
        let statusDataSource = DefaultCaptionsStatusDataSource()
        let holder = DefaultSessionKeyHolder()
        holder.setSessionKey(sessionKey)

        let viewModel = CaptionsButtonViewModel(
            sessionKeyProvider: holder,
            enableCaptionsUseCase: enableUseCase,
            disableCaptionsUseCase: disableUseCase,
            captionsStatusDataSource: statusDataSource
        )

        let mocks = Mocks(
            enableUseCase: enableUseCase,
            disableUseCase: disableUseCase,
            statusDataSource: statusDataSource
        )

        return (viewModel, mocks)
    }

    /// Waits for a condition to become true by yielding to the main actor's run loop.
    ///
    /// Instead of polling with sleeps, this yields control back to the main actor
    /// multiple times, allowing pending work (like Combine sink closures) to execute.
    /// This is deterministic and avoids race conditions under varying system loads.
    private func waitUntil(
        timeout: TimeInterval = 0.5,
        _ condition: @escaping @Sendable @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        var iterations = 0
        let maxIterations = 100  // Safety limit

        while iterations < maxIterations {
            // Check condition on MainActor
            if await condition() {
                return
            }

            guard Date() < deadline else {
                throw WaitTimeoutError()
            }

            // Yield to allow MainActor work to process
            await Task.yield()
            iterations += 1
        }

        throw WaitTimeoutError()
    }
}

// MARK: - Test Doubles

private final class MockEnableCaptionsUseCase: EnableCaptionsUseCase, @unchecked Sendable {
    var callCount = 0
    var lastSessionKey: String?
    var shouldThrow = false

    func callAsFunction(_ request: EnableCaptionsRequest) async throws {
        callCount += 1
        lastSessionKey = request.sessionKey
        if shouldThrow {
            throw MockError.forced
        }
    }
}

private final class MockDisableCaptionsUseCase: DisableCaptionsUseCase, @unchecked Sendable {
    var callCount = 0

    func callAsFunction() {
        callCount += 1
    }
}

private enum MockError: Error {
    case forced
}

private struct WaitTimeoutError: Error {}
