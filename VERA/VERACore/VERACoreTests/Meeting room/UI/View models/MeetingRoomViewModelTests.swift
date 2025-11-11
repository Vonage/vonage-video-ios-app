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
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let roomName = "heart-of-gold"
        let sut = makeSUT(
            roomName: roomName,
            connectToRoomUseCase: connectToRoomUseCase)

        #expect(sut.state == .loading)

        sut.loadUI()

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

        #expect(connectToRoomUseCase.recordedActions == [.connect(roomName)])

        #expect(sut.currentCall != nil)
        #expect(contentState.isMicEnabled == false)
        #expect(contentState.isCameraEnabled == false)
        #expect(contentState.participantsCount == 0)
    }

    @Test
    @MainActor
    func callingLoadUITwiceDoesNotConnectTwoRooms() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let roomName = "heart-of-gold"
        let sut = makeSUT(
            roomName: roomName,
            connectToRoomUseCase: connectToRoomUseCase)

        #expect(sut.state == .loading)

        sut.loadUI()
        sut.loadUI()

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

        #expect(connectToRoomUseCase.recordedActions == [.connect(roomName)])

        #expect(sut.currentCall != nil)
        #expect(contentState.isMicEnabled == false)
        #expect(contentState.isCameraEnabled == false)
        #expect(contentState.participantsCount == 0)
    }

    @Test
    @MainActor
    func callingLoadUICanFailAndShouldShowAnError() async throws {
        let connectToRoomUseCase = makeFailingMockConnectToRoomUseCase()
        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase)

        #expect(sut.state == .loading)

        sut.loadUI()

        let error = await sut.$error.values
            .first(where: { $0 != nil })!

        #expect(sut.currentCall == nil)
        #expect(error != nil)
    }

    @Test
    @MainActor
    func initialLayoutIsActiveSpeaker() async throws {
        let sut = makeSUT()

        sut.loadUI()

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

        #expect(contentState.layout == .activeSpeaker)
    }

    @Test
    @MainActor
    func layoutToggleSwitchesToGridLayout() async throws {
        let sut = makeSUT()

        sut.loadUI()
        sut.onToggleLayout()

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

        #expect(contentState.layout == .grid)
    }

    @Test
    @MainActor
    func toggleMicNotifiesToCurrentCall() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let call = connectToRoomUseCase.call
        let sut = makeSUT(connectToRoomUseCase: connectToRoomUseCase)
        sut.currentCall = call

        #expect(call.recordedActions == [])

        sut.onToggleMic()

        #expect(call.recordedActions == [.toggleLocalAudio])
    }

    @Test
    @MainActor
    func toggleCameraNotifiesToCurrentCall() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let call = connectToRoomUseCase.call
        let sut = makeSUT(connectToRoomUseCase: connectToRoomUseCase)
        sut.currentCall = call

        #expect(call.recordedActions == [])

        sut.onToggleCamera()

        #expect(call.recordedActions == [.toggleLocalVideo])
    }

    @Test
    @MainActor
    func cameraSwitchNotifiesToCurrentCall() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let call = connectToRoomUseCase.call
        let sut = makeSUT(connectToRoomUseCase: connectToRoomUseCase)
        sut.currentCall = call

        #expect(call.recordedActions == [])

        sut.onCameraSwitch()

        #expect(call.recordedActions == [.toggleLocalCamera])
    }

    @Test
    @MainActor
    func endCall_invokesDisconnectUseCase() async throws {
        let sessionRepository = makeMockSessionRepository()
        let connectToRoomUseCase = DefaultConnectToRoomUseCase(
            sessionRepository: sessionRepository,
            roomCredentialsRepository: makeMockRoomCredentialsRepository())
        let disconnectRoomUseCase = DefaultDisconnectRoomUseCase(
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

    @Test
    func checkRoomURL() async {
        let url = URL(string: "https://example.com")!
        let roomName = "heart-of-gold"
        let sut = makeSUT(
            roomName: roomName,
            baseURL: url)

        sut.loadUI()

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

        #expect(contentState.roomURL == url.appendingPathComponent(roomName))
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

extension MeetingRoomViewState {
    fileprivate var contentState: MeetingRoomState? {
        if case .content(let state) = self { return state }
        return nil
    }
}
