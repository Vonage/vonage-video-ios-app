//
//  Created by Vonage on 29/7/25.
//

import Foundation
import Testing
import VERACommonUI
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

        await sut.loadUI()

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

        await sut.loadUI()
        await sut.loadUI()

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

        await sut.loadUI()

        #expect(sut.currentCall == nil)
    }

    @Test
    @MainActor
    func callingLoadUICanFailAndShouldNavigateBackAfterConfirmation() async throws {
        let connectToRoomUseCase = makeFailingMockConnectToRoomUseCase()
        var alertErrorTriggered = false

        await confirmation("Alert should be presented") { confirm in
            let sut = makeSUT(
                connectToRoomUseCase: connectToRoomUseCase,
                actionHandler: { action in
                    if case .presentAlert = action {
                        alertErrorTriggered = true
                        confirm()
                    }
                }
            )

            #expect(sut.state == .loading)

            await sut.loadUI()
        }

        #expect(alertErrorTriggered, "Alert should be presented")
    }

    @Test
    @MainActor
    func initialLayoutIsActiveSpeaker() async throws {
        let sut = makeSUT()

        await sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.layout == .activeSpeaker)
    }

    @Test
    @MainActor
    func layoutToggleSwitchesToGridLayout() async throws {
        let sut = makeSUT()

        await sut.loadUI()

        sut.onToggleLayout()

        await delay()

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
        await sut.loadUI()

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
        await sut.loadUI()

        _ = try await getContentState(sut)

        #expect(sut.currentCall != nil)

        sut.endCall()

        await delay()

        #expect(sut.currentCall == nil)
    }

    @Test
    func checkRoomURL() async throws {
        guard let url = URL(string: "https://example.com") else { throw Error.nilValue }
        let roomName = "heart-of-gold"
        let sut = makeSUT(
            roomName: roomName,
            baseURL: url)

        await sut.loadUI()

        let contentState = try await getContentState(sut)
        #expect(contentState.roomURL == url.appendingPathComponent("room").appendingPathComponent(roomName))
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
        let checkCameraAuthorizationStatusUseCase = makeMockCheckCameraAuthorizationStatusUseCase(
            permissionStatus: .denied)
        let sut = makeSUT(
            checkCameraAuthorizationStatusUseCase: checkCameraAuthorizationStatusUseCase)

        await sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.isCameraEnabled == false)
    }

    @Test
    @MainActor
    func ifThereIsNoMicrophonePermissionMicrophoneShouldNotBeEnabled() async throws {
        let checkMicrophoneAuthorizationStatusUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(
            permissionStatus: .denied)
        let sut = makeSUT(
            checkMicrophoneAuthorizationStatusUseCase: checkMicrophoneAuthorizationStatusUseCase)

        await sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.isMicEnabled == false)
    }

    @Test("Given toggling the microphone, When the permission was denied, Then should present the Settings Alert")
    func toogleMicShouldShowSettingsMessage() async {
        let mockCheckMicUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(permissionStatus: .denied)

        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("Alert should presented for settings") { confirm in
            let sut = makeSUT(roomName: roomName, checkMicrophoneAuthorizationStatusUseCase: mockCheckMicUseCase) {
                action in
                switch action {
                case .presentAlert(let item):
                    navigateToSettingsAlert = item.title == "Check Settings"
                    confirm()
                default: break
                }
            }
            sut.onToggleMic()
        }

        #expect(navigateToSettingsAlert, "Should present Settings Alert")
    }

    @Test(
        "Given toggling the microphone presents a settings alert, When the user confirms, Then the app navigates to App Settings"
    )
    func toogleMicShouldShowSettingsMessageConfirmAndMoveToAppSetting() async {
        let mockCheckMicUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(permissionStatus: .denied)

        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("App settings should be presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkMicrophoneAuthorizationStatusUseCase: mockCheckMicUseCase) {
                action in
                switch action {
                case .presentAlert(let item):
                    item.onConfirm?()
                case .navigateToSettings:
                    navigateToSettingsAlert = true
                    confirm()
                default: break
                }
            }
            sut.onToggleMic()
        }

        #expect(navigateToSettingsAlert, "Should present App Settings")
    }

    @Test("Given toggling the camera, When the camera permission was denied, Then should present the Settings Alert")
    func toogleCameraShouldShowSettingsMessage() async {
        let mockCheckCameraUseCase = makeMockCheckCameraAuthorizationStatusUseCase(permissionStatus: .denied)
        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("Alert Setting should presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkCameraAuthorizationStatusUseCase: mockCheckCameraUseCase) {
                action in
                switch action {
                case .presentAlert(let item):
                    navigateToSettingsAlert = item.title == "Check Settings"
                    confirm()
                default: break
                }
            }
            sut.onToggleCamera()
        }

        #expect(navigateToSettingsAlert, "Should present Settings Alert")
    }

    @Test(
        "Given toggling the camera presents the Alert Settings, When the user confirms, Then the app navigates to App Settings"
    )
    func toogleCameraShouldShowSettingsMessageUserConfirmsAndNavigatesToAppSetting() async {
        let mockCheckCameraUseCase = makeMockCheckCameraAuthorizationStatusUseCase(permissionStatus: .denied)

        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("App settings should be presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkCameraAuthorizationStatusUseCase: mockCheckCameraUseCase) {
                action in
                switch action {
                case .presentAlert(let item):
                    item.onConfirm?()
                case .navigateToSettings:
                    navigateToSettingsAlert = true
                    confirm()
                default: break
                }
            }
            sut.onToggleCamera()
        }

        #expect(navigateToSettingsAlert, "Should present App Settings")
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
        currentCallParticipantsRepository: CurrentCallParticipantsRepository =
            makeMockCurrentCallParticipantsRepository(),
        appConfig: AppConfig = AppConfig(),
        actionHandler: ActionHandler? = nil
    ) -> MeetingRoomViewModel {
        MeetingRoomViewModel(
            roomName: roomName,
            baseURL: baseURL,
            connectToRoomUseCase: connectToRoomUseCase,
            disconnectRoomUseCase: disconnectRoomUseCase,
            checkMicrophoneAuthorizationStatusUseCase: checkMicrophoneAuthorizationStatusUseCase,
            checkCameraAuthorizationStatusUseCase: checkCameraAuthorizationStatusUseCase,
            currentCallParticipantsRepository: currentCallParticipantsRepository,
            appConfig: appConfig,
            meetingRoomNavigation: MockMeetingRoomNavigation(actionHandler, roomName: roomName),
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

        await sut.loadUI()

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
