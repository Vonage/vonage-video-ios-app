//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACaptions

@Suite("DefaultEnableCaptionsUseCase Tests")
struct DefaultEnableCaptionsUseCaseTests {

    @Test("Success calls data source and sets status to enabled with captionsId")
    func successSetsEnabledState() async throws {
        let (sut, mocks) = makeSUT()
        mocks.dataSource.enableResult = .success(.init(captionsId: "captions-abc"))

        try await sut(.init(roomName: "my-room"))

        #expect(mocks.dataSource.enableCallCount == 1)
        #expect(mocks.dataSource.lastRoomName == "my-room")

        let state = try await currentState(mocks.statusDataSource)
        #expect(state == .enabled("captions-abc"))
    }

    @Test("Failure propagates error and does not set status")
    func failureDoesNotSetStatus() async throws {
        let (sut, mocks) = makeSUT()
        mocks.dataSource.enableResult = .failure(MockError.forced)

        await #expect(throws: MockError.self) {
            try await sut(.init(roomName: "room"))
        }

        #expect(mocks.dataSource.enableCallCount == 1)

        let state = try await currentState(mocks.statusDataSource)
        #expect(state == .disabled)
    }

    // MARK: - Helpers

    private struct Mocks {
        let dataSource: MockCaptionsActivationDataSource
        let statusDataSource: DefaultCaptionsStatusDataSource
    }

    private func makeSUT() -> (DefaultEnableCaptionsUseCase, Mocks) {
        let dataSource = MockCaptionsActivationDataSource()
        let statusDataSource = DefaultCaptionsStatusDataSource()
        let sut = DefaultEnableCaptionsUseCase(
            captionsActivationDataSource: dataSource,
            captionsStatusDataSource: statusDataSource
        )
        return (sut, Mocks(dataSource: dataSource, statusDataSource: statusDataSource))
    }

    private func currentState(
        _ dataSource: DefaultCaptionsStatusDataSource
    ) async throws -> CaptionsState {
        var state: CaptionsState = .disabled
        let cancellable = dataSource.captionsState.sink { state = $0 }
        _ = cancellable
        return state
    }
}

// MARK: - Test Doubles

private final class MockCaptionsActivationDataSource: CaptionsActivationDataSource, @unchecked Sendable {
    var enableCallCount = 0
    var lastRoomName: String?
    var enableResult: Result<EnableCaptionsDataSourceResponse, Error> = .success(.init(captionsId: "default-id"))

    func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse {
        enableCallCount += 1
        lastRoomName = request.roomName
        return try enableResult.get()
    }
}

private enum MockError: Error {
    case forced
}
