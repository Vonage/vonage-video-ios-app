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

    enum Error: Swift.Error {
        case nilValue
    }

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

        let contentState = try await getContentState(sut)

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

        let contentState = try await getContentState(sut)

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

        let error =
            try await sut.$error.values
            .first { $0 != nil } ?? { throw Error.nilValue }()

        #expect(sut.currentCall == nil)
        #expect(error != nil)
    }

    @Test
    @MainActor
    func callingLoadUICanFailAndShouldNavigateBackAfterConfirmation() async throws {
        let connectToRoomUseCase = makeFailingMockConnectToRoomUseCase()
        var navigationTriggered = false

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            onBack: {
                navigationTriggered = true
            })

        #expect(sut.state == .loading)

        sut.loadUI()

        let error =
            try await sut.$error.values
            .first { $0 != nil } ?? { throw Error.nilValue }()
        error?.onConfirm?()

        #expect(navigationTriggered == true)
    }

    @Test
    @MainActor
    func initialLayoutIsActiveSpeaker() async throws {
        let sut = makeSUT()

        sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.layout == .activeSpeaker)
    }

    @Test
    @MainActor
    func layoutToggleSwitchesToGridLayout() async throws {
        let sut = makeSUT()

        sut.loadUI()
        sut.onToggleLayout()

        let contentState = try await getContentState(sut)

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
        let disconnectRoomUseCase = makeMockDisconnectRoomUseCase()

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase
        )
        sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(sut.currentCall != nil)
        #expect(contentState.isMicEnabled == false)
        #expect(contentState.isCameraEnabled == false)
        #expect(contentState.participantsCount == 0)

        sut.endCall()

        await delay()

        #expect(disconnectRoomUseCase.recordedActions == [.disconnect])
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

        _ = try await getContentState(sut)

        #expect(sut.currentCall != nil)

        sut.endCall()

        let error =
            try await sut.$error.values
            .first { $0 != nil } ?? { throw Error.nilValue }()

        #expect(sut.currentCall == nil)
        #expect(error != nil)
    }

    @Test
    func checkRoomURL() async throws {
        guard let url = URL(string: "https://example.com") else { throw Error.nilValue }
        let roomName = "heart-of-gold"
        let sut = makeSUT(
            roomName: roomName,
            baseURL: url)

        sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.roomURL == url.appendingPathComponent(roomName))
    }

    @Test
    func activateMicrophoneControlIfActivatedInAppConfig() async throws {
        let appConfig = AppConfig(audioSettings: AppConfig.AudioSettings(allowMicrophoneControl: true))

        let contentState = try await when(given: appConfig)

        #expect(contentState.allowMicrophoneControl == true)
    }

    @Test
    func deactivateMicrophoneControlIfDeactivatedInAppConfig() async throws {
        let appConfig = AppConfig(audioSettings: AppConfig.AudioSettings(allowMicrophoneControl: false))

        let contentState = try await when(given: appConfig)

        #expect(contentState.allowMicrophoneControl == false)
    }

    @Test
    func activateCameraControlIfActivatedInAppConfig() async throws {
        let appConfig = AppConfig(videoSettings: AppConfig.VideoSettings(allowCameraControl: true))

        let contentState = try await when(given: appConfig)

        #expect(contentState.allowCameraControl == true)
    }

    @Test
    func deactivateCameraControlIfDeactivatedInAppConfig() async throws {
        let appConfig = AppConfig(videoSettings: AppConfig.VideoSettings(allowCameraControl: false))

        let contentState = try await when(given: appConfig)

        #expect(contentState.allowCameraControl == false)
    }

    @Test
    func showParticipantListIfActivatedInAppConfig() async throws {
        let appConfig = AppConfig(meetingRoomSettings: AppConfig.MeetingRoomSettings(showParticipantList: true))

        let contentState = try await when(given: appConfig)

        #expect(contentState.showParticipantList == true)
    }

    @Test
    func hideParticipantListIfDeactivatedInAppConfig() async throws {
        let appConfig = AppConfig(meetingRoomSettings: AppConfig.MeetingRoomSettings(showParticipantList: false))

        let contentState = try await when(given: appConfig)

        #expect(contentState.showParticipantList == false)
    }

    @Test
    @MainActor
    func ifThereIsNoCameraPermissionCameraShouldNotBeEnabled() async throws {
        let checkCameraAuthorizationStatusUseCase = makeMockCheckCameraAuthorizationStatusUseCase(isAuthorized: false)
        let sut = makeSUT(
            checkCameraAuthorizationStatusUseCase: checkCameraAuthorizationStatusUseCase)

        sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.isCameraEnabled == false)
    }

    @Test
    @MainActor
    func ifThereIsNoMicrophonePermissionMicrophoneShouldNotBeEnabled() async throws {
        let checkMicrophoneAuthorizationStatusUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(
            isAuthorized: false)
        let sut = makeSUT(
            checkMicrophoneAuthorizationStatusUseCase: checkMicrophoneAuthorizationStatusUseCase)

        sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.isMicEnabled == false)
    }

    // MARK: SUT

    func makeSUT(
        roomName: String = "a_room_name",
        baseURL: URL = .init(string: "https://example.com")!,
        connectToRoomUseCase: ConnectToRoomUseCase = makeMockConnectToRoomUseCase(),
        disconnectRoomUseCase: DisconnectRoomUseCase = makeMockDisconnectRoomUseCase(),
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase =
            makeMockCheckMicrophoneAuthorizationStatusUseCase(),
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase =
            makeMockCheckCameraAuthorizationStatusUseCase(),
        requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase =
            makeMockRequestMicrophonePermissionUseCase(),
        requestCameraPermissionUseCase: RequestCameraPermissionUseCase = makeMockRequestCameraPermissionUseCase(),
        currentCallParticipantsRepository: CurrentCallParticipantsRepository =
            makeMockCurrentCallParticipantsRepository(),
        appConfig: AppConfig = AppConfig(),
        onBack: @escaping () -> Void = {},
        onShowChat: @escaping () -> Void = {},
        onNext: @escaping () -> Void = {}
    ) -> MeetingRoomViewModel {
        MeetingRoomViewModel(
            roomName: roomName,
            baseURL: baseURL,
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase,
            checkMicrophoneAuthorizationStatusUseCase: checkMicrophoneAuthorizationStatusUseCase,
            checkCameraAuthorizationStatusUseCase: checkCameraAuthorizationStatusUseCase,
            requestMicrophonePermissionUseCase: requestMicrophonePermissionUseCase,
            requestCameraPermissionUseCase: requestCameraPermissionUseCase,
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            appConfig: appConfig,
            meetingRoomNavigation: .init(onBack: onBack, onNext: onNext),
            getExternalButtons: { _ in [] })
    }

    // MARK: Helper

    func getContentState(_ sut: MeetingRoomViewModel) async throws -> MeetingRoomState {
        try await sut.$state.values
            .compactMap(\.contentState)
            .first { _ in true } ?? { throw Error.nilValue }()
    }

    func when(given appConfig: AppConfig) async throws -> MeetingRoomState {
        let sut = makeSUT(appConfig: appConfig)

        sut.loadUI()

        let contentState =
            try await sut.$state.values
            .compactMap(\.contentState)
            .first { _ in true } ?? { throw Error.nilValue }()

        return contentState
    }
}

extension MeetingRoomViewState {
    fileprivate var contentState: MeetingRoomState? {
        if case .content(let state) = self { return state }
        return nil
    }
}
