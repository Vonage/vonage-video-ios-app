//
//  Created by Vonage on 29/7/25.
//

import Foundation
import Testing
import VERACore
import VERATestHelpers

@Suite("MeetingRoomViewModel tests")
struct MeetingRoomViewModelTests {

    @Test
    @MainActor
    func initialStateIsContentIsLoading() async throws {
        let sut = makeSUT()
        #expect(sut.state == .loading)
    }

    @Test
    @MainActor
    func loadUI_loadsACall() async throws {
        let sut = makeSUT()
        sut.loadUI()

        let contentState = try await awaitContentState(for: sut)
        #expect(sut.currentCall != nil)
        #expect(contentState.isMicEnabled == false)
        #expect(contentState.isCameraEnabled == false)
        #expect(contentState.participantsCount == 0)
    }

    @Test
    @MainActor
    func endCall_invokesDisconnectUseCase() async throws {
        let sessionRepository = makeMockSessionRepository()
        let connectToRoomUseCase = ConnectToRoomUseCase(
            sessionRepository: sessionRepository,
            roomCredentialsRepository: makeMockRoomCredentialsRepository())
        let disconnectRoomUseCase = DisconnectRoomUseCase(
            sessionRepository: sessionRepository,
            publisherRepository: makeMockVERAPublisherRepository())

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase
        )
        sut.loadUI()

        let contentState = try await awaitContentState(for: sut)
        #expect(sut.currentCall != nil)
        #expect(contentState.isMicEnabled == false)
        #expect(contentState.isCameraEnabled == false)
        #expect(contentState.participantsCount == 0)

        sut.endCall()

        await delay()

        #expect(sessionRepository.currentCall == nil)
        #expect(sut.currentCall == nil)
    }

    // MARK: SUT

    func makeSUT(
        roomName: String = "a_room_name",
        connectToRoomUseCase: ConnectToRoomUseCase = makeMockConnectToRoomUseCase(),
        disconnectRoomUseCase: DisconnectRoomUseCase = makeMockDisconnectRoomUseCase(),
        currentCallParticipantsRepository: CurrentCallParticipantsRepository =
            makeMockCurrentCallParticipantsRepository()
    ) -> MeetingRoomViewModel {
        MeetingRoomViewModel(
            roomName: roomName,
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase,
            currentCallParticipantsRepository: currentCallParticipantsRepository)
    }
    
    @discardableResult
    func awaitContentState(
        for viewModel: MeetingRoomViewModel,
        timeout: UInt64 = 2_000_000_000 // 2 seconds
    ) async throws -> MeetingRoomState {
        let sequence = viewModel.$state.values
        let task = Task<MeetingRoomState, Error> {
            for await value in sequence {
                if case .content(let contentState) = value {
                    return contentState
                }
            }
            throw NSError(domain: "Timeout", code: 1)
        }
        let timeoutTask = Task<MeetingRoomState, Error> {
            try await Task.sleep(nanoseconds: timeout)
            throw NSError(domain: "Timeout", code: 2)
        }
        let result = try await withThrowingTaskGroup(of: MeetingRoomState.self) { group in
            group.addTask { try await task.value }
            group.addTask { try await timeoutTask.value }
            guard let value = try await group.next() else {
                throw NSError(domain: "Timeout", code: 3)
            }
            group.cancelAll()
            return value
        }
        return result
    }
}

// MARK: - Mocks

func makeMockConnectToRoomUseCase() -> ConnectToRoomUseCase {
    .init(
        sessionRepository: makeMockSessionRepository(),
        roomCredentialsRepository: makeMockRoomCredentialsRepository())
}

func makeMockDisconnectRoomUseCase() -> DisconnectRoomUseCase {
    .init(
        sessionRepository: makeMockSessionRepository(),
        publisherRepository: makeMockVERAPublisherRepository())
}
