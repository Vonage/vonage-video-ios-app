//
//  Created by Vonage on 29/7/25.
//

import Foundation
import Testing
import VERAConfiguration
import VERACore
import VERADomain
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
    @MainActor
    func endCallShowsErrorIfDisconnectCallFails() async throws {
        let sessionRepository = makeMockSessionRepository()
        let connectToRoomUseCase = DefaultConnectToRoomUseCase(
            sessionRepository: sessionRepository,
            roomCredentialsRepository: makeMockRoomCredentialsRepository())
        let disconnectRoomUseCase = makeFailingMockDisconnectRoomUseCase(
            sessionRepository: sessionRepository,
            publisherRepository: makeMockVERAPublisherRepository())

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase
        )
        sut.loadUI()

        let _ = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

        #expect(sut.currentCall != nil)

        sut.endCall()

        let error = await sut.$error.values
            .first(where: { $0 != nil })!

        #expect(sut.currentCall == nil)
        #expect(error != nil)
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

    @Test
    func showChatURLIfActivatedInAppConfig() async {
        let appConfig = AppConfig(meetingRoomSettings: AppConfig.MeetingRoomSettings(allowChat: true))

        let contentState = await when(given: appConfig)

        #expect(contentState.showChatButton == true)
    }

    @Test
    func hideChatURLIfDeactivatedInAppConfig() async {
        let appConfig = AppConfig(meetingRoomSettings: AppConfig.MeetingRoomSettings(allowChat: false))

        let contentState = await when(given: appConfig)

        #expect(contentState.showChatButton == false)
    }

    @Test
    func activateMicrophoneControlIfActivatedInAppConfig() async {
        let appConfig = AppConfig(audioSettings: AppConfig.AudioSettings(allowMicrophoneControl: true))

        let contentState = await when(given: appConfig)

        #expect(contentState.allowMicrophoneControl == true)
    }

    @Test
    func deactivateMicrophoneControlIfDeactivatedInAppConfig() async {
        let appConfig = AppConfig(audioSettings: AppConfig.AudioSettings(allowMicrophoneControl: false))

        let contentState = await when(given: appConfig)

        #expect(contentState.allowMicrophoneControl == false)
    }

    @Test
    func activateCameraControlIfActivatedInAppConfig() async {
        let appConfig = AppConfig(videoSettings: AppConfig.VideoSettings(allowCameraControl: true))

        let contentState = await when(given: appConfig)

        #expect(contentState.allowCameraControl == true)
    }

    @Test
    func deactivateCameraControlIfDeactivatedInAppConfig() async {
        let appConfig = AppConfig(videoSettings: AppConfig.VideoSettings(allowCameraControl: false))

        let contentState = await when(given: appConfig)

        #expect(contentState.allowCameraControl == false)
    }

    @Test
    func showParticipantListIfActivatedInAppConfig() async {
        let appConfig = AppConfig(meetingRoomSettings: AppConfig.MeetingRoomSettings(showParticipantList: true))

        let contentState = await when(given: appConfig)

        #expect(contentState.showParticipantList == true)
    }

    @Test
    func hideParticipantListIfDeactivatedInAppConfig() async {
        let appConfig = AppConfig(meetingRoomSettings: AppConfig.MeetingRoomSettings(showParticipantList: false))

        let contentState = await when(given: appConfig)

        #expect(contentState.showParticipantList == false)
    }

    // MARK: SUT

    func makeSUT(
        roomName: String = "a_room_name",
        baseURL: URL = .init(string: "https://example.com")!,
        connectToRoomUseCase: ConnectToRoomUseCase = makeMockConnectToRoomUseCase(),
        disconnectRoomUseCase: DisconnectRoomUseCase = makeMockDisconnectRoomUseCase(),
        currentCallParticipantsRepository: CurrentCallParticipantsRepository =
            makeMockCurrentCallParticipantsRepository(),
        appConfig: AppConfig = AppConfig()
    ) -> MeetingRoomViewModel {
        MeetingRoomViewModel(
            roomName: roomName,
            baseURL: baseURL,
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase,
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            appConfig: appConfig)
    }

    // MARK: Helper

    func when(given appConfig: AppConfig) async -> MeetingRoomState {
        let sut = makeSUT(appConfig: appConfig)

        sut.loadUI()

        let contentState = await sut.$state.values
            .compactMap(\.contentState)
            .first(where: { _ in true })!

        return contentState
    }
}

extension MeetingRoomViewState {
    fileprivate var contentState: MeetingRoomState? {
        if case .content(let state) = self { return state }
        return nil
    }
}
