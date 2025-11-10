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

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

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

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

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
        baseURL: URL = .init(string: "https://example.com")!,
        connectToRoomUseCase: ConnectToRoomUseCase = makeMockConnectToRoomUseCase(),
        disconnectRoomUseCase: DisconnectRoomUseCase = makeMockDisconnectRoomUseCase(),
        currentCallParticipantsRepository: CurrentCallParticipantsRepository =
            makeMockCurrentCallParticipantsRepository()
    ) -> MeetingRoomViewModel {
        MeetingRoomViewModel(
            roomName: roomName,
            baseURL: baseURL,
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase,
            currentCallParticipantsRepository: currentCallParticipantsRepository)
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

extension MeetingRoomViewState {
    fileprivate var contentState: MeetingRoomState? {
        if case .content(let state) = self { return state }
        return nil
    }
}
