//
//  Created by Vonage on 29/7/25.
//

import Foundation
import Testing
import VERACommonUI
import VERADomain
import VERAMeetingRoom
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
        let configuration = MeetingRoomConfiguration(allowMicrophoneControl: true)

        let contentState = try await when(given: configuration)

        #expect(contentState.allowMicrophoneControl == true)
    }

    @Test
    func deactivateMicrophoneControlIfDeactivatedInAppConfig() async throws {
        let configuration = MeetingRoomConfiguration(allowMicrophoneControl: false)

        let contentState = try await when(given: configuration)

        #expect(contentState.allowMicrophoneControl == false)
    }

    @Test
    func activateCameraControlIfActivatedInAppConfig() async throws {
        let configuration = MeetingRoomConfiguration(allowCameraControl: true)

        let contentState = try await when(given: configuration)

        #expect(contentState.allowCameraControl == true)
    }

    @Test
    func deactivateCameraControlIfDeactivatedInAppConfig() async throws {
        let configuration = MeetingRoomConfiguration(allowCameraControl: false)

        let contentState = try await when(given: configuration)

        #expect(contentState.allowCameraControl == false)
    }

    @Test
    func showParticipantListIfActivatedInAppConfig() async throws {
        let configuration = MeetingRoomConfiguration(showParticipantList: true)

        let contentState = try await when(given: configuration)

        #expect(contentState.showParticipantList == true)
    }

    @Test
    func hideParticipantListIfDeactivatedInAppConfig() async throws {
        let configuration = MeetingRoomConfiguration(showParticipantList: false)

        let contentState = try await when(given: configuration)

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

    // MARK: - Noise Suppression Tests

    @Test("Initial noise suppression state is idle")
    @MainActor
    func initialNoiseSuppressionStateIsIdle() async throws {
        let dataSource = makeMockNoiseSuppressionStatusDataSource()
        let sut = makeSUT(noiseSuppressionStatusDataSource: dataSource)

        await sut.loadUI()

        let contentState = try await getContentState(sut)

        #expect(contentState.noiseSuppressionState == .idle)
    }

    @Test("When noise suppression is enabled, state updates to enabled")
    @MainActor
    func whenNoiseSuppressionIsEnabled_stateUpdatesToEnabled() async throws {
        let dataSource = makeMockNoiseSuppressionStatusDataSource()
        let sut = makeSUT(noiseSuppressionStatusDataSource: dataSource)

        await sut.loadUI()

        let initialState = try await getContentState(sut)
        #expect(initialState.noiseSuppressionState == .idle)

        dataSource.set(state: .enabled)

        let updatedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.noiseSuppressionState == .enabled }

        #expect(updatedState?.noiseSuppressionState == .enabled)
    }

    @Test("When noise suppression is disabled, state updates to disabled")
    @MainActor
    func whenNoiseSuppressionIsDisabled_stateUpdatesToDisabled() async throws {
        let dataSource = makeMockNoiseSuppressionStatusDataSource()
        let sut = makeSUT(noiseSuppressionStatusDataSource: dataSource)

        await sut.loadUI()

        dataSource.set(state: .disabled)

        let updatedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.noiseSuppressionState == .disabled }

        #expect(updatedState?.noiseSuppressionState == .disabled)
    }

    @Test("Noise suppression state transitions are reflected in view state")
    @MainActor
    func noiseSuppressionStateTransitionsAreReflectedInViewState() async throws {
        let dataSource = makeMockNoiseSuppressionStatusDataSource()
        let sut = makeSUT(noiseSuppressionStatusDataSource: dataSource)

        await sut.loadUI()

        // Idle -> Enabled
        dataSource.set(state: .enabled)

        let enabledState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.noiseSuppressionState == .enabled }

        #expect(enabledState?.noiseSuppressionState == .enabled)

        // Enabled -> Disabled
        dataSource.set(state: .disabled)

        let disabledState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.noiseSuppressionState == .disabled }

        #expect(disabledState?.noiseSuppressionState == .disabled)
    }

    @Test("Noise suppression changes do not affect other state properties")
    @MainActor
    func noiseSuppressionChangesDoNotAffectOtherProperties() async throws {
        let dataSource = makeMockNoiseSuppressionStatusDataSource()
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let roomName = "test-room"

        let sut = makeSUT(
            roomName: roomName,
            connectToRoomUseCase: connectToRoomUseCase,
            noiseSuppressionStatusDataSource: dataSource
        )

        await sut.loadUI()

        let initialState = try await getContentState(sut)

        dataSource.set(state: .enabled)

        let updatedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.noiseSuppressionState == .enabled }

        // Verify other properties remain unchanged
        #expect(updatedState?.roomName == initialState.roomName)
        #expect(updatedState?.isMicEnabled == initialState.isMicEnabled)
        #expect(updatedState?.isCameraEnabled == initialState.isCameraEnabled)
        #expect(updatedState?.participantsCount == initialState.participantsCount)
    }

    // MARK: - Pin / Unpin Tests

    @Test("Given a participant, When the user pins them, Then the participant isPinned becomes true")
    @MainActor
    func pinParticipant_updatesIsPinnedToTrue() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let mockCall = connectToRoomUseCase.call
        let pinnedDataSource = DefaultPinnedParticipantsDataSource()

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            pinnedParticipantsDataSource: pinnedDataSource
        )

        await sut.loadUI()

        let participant = makeMockParticipant(id: "p1", name: "Alice")
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: [participant], activeParticipantId: nil)
        )

        let initialState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participantsCount == 1 }
        #expect(initialState?.participants.first(where: { $0.id == "p1" })?.isPinned == false)

        sut.onTogglePin(participantId: "p1")

        let updatedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participants.contains(where: { $0.id == "p1" && $0.isPinned }) }

        let pinnedParticipant = try #require(updatedState?.participants.first(where: { $0.id == "p1" }))
        #expect(pinnedParticipant.isPinned == true)
    }

    @Test("Given a pinned participant, When the user unpins them, Then the participant isPinned becomes false")
    @MainActor
    func unpinParticipant_updatesIsPinnedToFalse() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let mockCall = connectToRoomUseCase.call
        let pinnedDataSource = DefaultPinnedParticipantsDataSource()

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            pinnedParticipantsDataSource: pinnedDataSource
        )

        await sut.loadUI()

        let participant = makeMockParticipant(id: "p1", name: "Alice")
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: [participant], activeParticipantId: nil)
        )

        // Pin the participant first
        sut.onTogglePin(participantId: "p1")

        let pinnedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participants.contains(where: { $0.id == "p1" && $0.isPinned }) }
        #expect(pinnedState?.participants.first(where: { $0.id == "p1" })?.isPinned == true)

        // Unpin the participant
        sut.onTogglePin(participantId: "p1")

        let updatedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participants.contains(where: { $0.id == "p1" && !$0.isPinned }) }

        let unpinnedParticipant = try #require(updatedState?.participants.first(where: { $0.id == "p1" }))
        #expect(unpinnedParticipant.isPinned == false)
    }

    @Test("Given multiple participants, When one is pinned, Then only that participant isPinned is true")
    @MainActor
    func pinOneOfMultipleParticipants_onlyPinnedParticipantHasIsPinnedTrue() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let mockCall = connectToRoomUseCase.call
        let pinnedDataSource = DefaultPinnedParticipantsDataSource()

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            pinnedParticipantsDataSource: pinnedDataSource
        )

        await sut.loadUI()

        let participants = [
            makeMockParticipant(id: "p1", name: "Alice"),
            makeMockParticipant(id: "p2", name: "Bob"),
            makeMockParticipant(id: "p3", name: "Charlie"),
        ]
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: participants, activeParticipantId: nil)
        )

        let initialState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participantsCount == 3 }
        #expect(initialState?.participantsCount == 3)

        sut.onTogglePin(participantId: "p2")

        let updatedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participants.contains(where: { $0.id == "p2" && $0.isPinned }) }

        let stateParticipants = try #require(updatedState?.participants)

        let alice = try #require(stateParticipants.first(where: { $0.id == "p1" }))
        let bob = try #require(stateParticipants.first(where: { $0.id == "p2" }))
        let charlie = try #require(stateParticipants.first(where: { $0.id == "p3" }))

        #expect(alice.isPinned == false)
        #expect(bob.isPinned == true)
        #expect(charlie.isPinned == false)
    }

    @Test(
        "Given 3 participants are already pinned, When checking canBePinned for an unpinned participant, Then canBePinned is false"
    )
    @MainActor
    func pinCapacity_whenThreeParticipantsPinned_canBePinnedIsFalse() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let mockCall = connectToRoomUseCase.call
        let pinnedDataSource = DefaultPinnedParticipantsDataSource()

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            pinnedParticipantsDataSource: pinnedDataSource
        )

        await sut.loadUI()

        let participants = [
            makeMockParticipant(id: "p1", name: "Alice"),
            makeMockParticipant(id: "p2", name: "Bob"),
            makeMockParticipant(id: "p3", name: "Charlie"),
            makeMockParticipant(id: "p4", name: "Dave"),
        ]
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: participants, activeParticipantId: nil)
        )

        let initialState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participantsCount == 4 }
        #expect(initialState?.participantsCount == 4)

        // Pin 3 participants
        sut.onTogglePin(participantId: "p1")
        sut.onTogglePin(participantId: "p2")
        sut.onTogglePin(participantId: "p3")

        let updatedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { state in
                state.participants.filter(\.isPinned).count == 3
            }

        let dave = try #require(updatedState?.participants.first(where: { $0.id == "p4" }))
        #expect(dave.isPinned == false)
        #expect(dave.canBePinned == false)

        // Pinned participants should still be able to toggle (unpin)
        let alice = try #require(updatedState?.participants.first(where: { $0.id == "p1" }))
        #expect(alice.isPinned == true)
        #expect(alice.canTogglePinState == true)
    }

    @Test(
        "Given 3 pinned participants including a screen share, When the screen share leaves, Then pin counter is restored and canBePinned becomes true"
    )
    @MainActor
    func pinCapacity_whenPinnedScreenShareLeaves_canBePinnedIsRestored() async throws {
        let connectToRoomUseCase = makeMockConnectToRoomUseCase()
        let mockCall = connectToRoomUseCase.call
        let pinnedDataSource = DefaultPinnedParticipantsDataSource()

        let sut = makeSUT(
            connectToRoomUseCase: connectToRoomUseCase,
            pinnedParticipantsDataSource: pinnedDataSource
        )

        await sut.loadUI()

        let participants = [
            makeMockParticipant(id: "p1", name: "Alice"),
            makeMockParticipant(id: "p2", name: "Bob"),
            makeMockParticipant(id: "p3", name: "Charlie"),
            makeMockParticipant(id: "screen1", name: "ScreenShare", isScreenshare: true),
        ]
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: participants, activeParticipantId: nil)
        )

        let initialState = await sut.$state.values
            .compactMap(\.contentState)
            .first { $0.participants.count == 4 }
        #expect(initialState?.participants.count == 4)

        // Pin 3 participants: Alice, Bob, and the screen share
        sut.onTogglePin(participantId: "p1")
        sut.onTogglePin(participantId: "p2")
        sut.onTogglePin(participantId: "screen1")

        let pinnedState = await sut.$state.values
            .compactMap(\.contentState)
            .first { state in
                state.participants.filter(\.isPinned).count == 3
            }

        // Verify Charlie cannot be pinned (3 slots used)
        let charlieBeforeRemoval = try #require(pinnedState?.participants.first(where: { $0.id == "p3" }))
        #expect(charlieBeforeRemoval.canBePinned == false)

        // Screen share session ends — remove it from participants
        let remainingParticipants = [
            makeMockParticipant(id: "p1", name: "Alice"),
            makeMockParticipant(id: "p2", name: "Bob"),
            makeMockParticipant(id: "p3", name: "Charlie"),
        ]
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: remainingParticipants, activeParticipantId: nil)
        )

        // Verify Charlie can now be pinned (stale screen share ID no longer counts)
        let restoredState = await sut.$state.values
            .compactMap(\.contentState)
            .first { state in
                state.participants.filter(\.isPinned).count == 2
                    && state.participants.first(where: { $0.id == "p3" })?.canBePinned == true
            }

        let charlieAfterRemoval = try #require(restoredState?.participants.first(where: { $0.id == "p3" }))
        #expect(charlieAfterRemoval.canBePinned == true)
        #expect(charlieAfterRemoval.isPinned == false)

        // Alice and Bob should still be pinned
        let aliceAfter = try #require(restoredState?.participants.first(where: { $0.id == "p1" }))
        let bobAfter = try #require(restoredState?.participants.first(where: { $0.id == "p2" }))
        #expect(aliceAfter.isPinned == true)
        #expect(bobAfter.isPinned == true)
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
        configuration: MeetingRoomConfiguration = MeetingRoomConfiguration(),
        noiseSuppressionStatusDataSource: NoiseSuppressionStatusDataSource = makeMockNoiseSuppressionStatusDataSource(),
        pinnedParticipantsDataSource: PinnedParticipantsDataSource = DefaultPinnedParticipantsDataSource(),
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
            captionsStatusDataSource: NullCaptionsStatusDataSource(),
            configuration: configuration,
            meetingRoomNavigation: MockMeetingRoomNavigation(actionHandler, roomName: roomName),
            getExternalButtons: { _ in [] },
            noiseSuppressionStatusDataSource: noiseSuppressionStatusDataSource,
            pinnedParticipantsDataSource: pinnedParticipantsDataSource
        )
    }

    // MARK: Helper

    func getContentState(_ sut: MeetingRoomViewModel) async throws -> MeetingRoomState {
        try await sut.$state.values
            .compactMap(\.contentState)
            .first { _ in true } ?? { throw Error.nilValue }()
    }

    func when(given configuration: MeetingRoomConfiguration) async throws -> MeetingRoomState {
        let sut = makeSUT(configuration: configuration)

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
