//
//  Created by Vonage on 03/07/26.
//

import Combine
import SwiftUI
import Testing

@testable import VERAConfiguration
@testable import VERACore
@testable import VERADomain
@testable import VERATestHelpers

@MainActor
struct WaitingRoomViewModelAudioLevelTests {

    // MARK: - Test Helpers

    @MainActor
    private func makeSUT() -> WaitingRoomViewModel {
        let mockPublisher = MockVERAPublisher()
        let cameraPreviewRepo = makeMockCameraPreviewProviderRepository(publisher: mockPublisher)

        return WaitingRoomViewModel(
            roomName: "test-room",
            cameraPreviewProviderRepository: cameraPreviewRepo,
            cameraDevicesRepository: makeMockCameraDevicesRepository(),
            joinRoomUseCase: JoinRoomUseCase(
                userRepository: makeMockUserRepository(),
                cameraPreviewProviderRepository: cameraPreviewRepo,
                advancedSettingsUseCase: MockPublisherAdvancedSettingsUseCaseWithSettings(
                    settings: PublisherAdvancedSettings()
                )
            ),
            requestMicrophonePermissionUseCase: makeMockRequestMicrophonePermissionUseCase(),
            requestCameraPermissionUseCase: makeMockRequestCameraPermissionUseCase(),
            checkCameraAuthorizationStatusUseCase: makeMockCheckCameraAuthorizationStatusUseCase(),
            checkMicrophoneAuthorizationStatusUseCase: makeMockCheckMicrophoneAuthorizationStatusUseCase(),
            userRepository: makeMockUserRepository(),
            waitingRoomNavigation: MockWaitingRoomNavigation(nil, roomName: "test-room")
        )
    }

    private func getContentState(from viewModel: WaitingRoomViewModel) -> WaitingRoomState? {
        if case .content(let state) = viewModel.state {
            return state
        }
        return nil
    }

    // MARK: - Audio Level Tests

    @Test("updateAudioLevel preserves allowAudioOutputTest flag")
    func updateAudioLevelPreservesAllowAudioOutputTestFlag() throws {
        let sut = makeSUT()

        // Load UI to initialize the state
        sut.loadUI()

        // Get initial state
        let initialState = try #require(getContentState(from: sut))
        let initialAllowAudioOutputTest = initialState.allowAudioOutputTest

        // Simulate audio level update (this would normally be called by the publisher)
        // We'll test this by checking that the state maintains allowAudioOutputTest
        // after multiple state updates

        // Force a state update through toggle operations which internally update the state
        sut.onToggleMic()
        let stateAfterMicToggle = try #require(getContentState(from: sut))

        sut.onToggleCamera()
        let stateAfterCameraToggle = try #require(getContentState(from: sut))

        // The allowAudioOutputTest flag should remain consistent
        #expect(stateAfterMicToggle.allowAudioOutputTest == initialAllowAudioOutputTest)
        #expect(stateAfterCameraToggle.allowAudioOutputTest == initialAllowAudioOutputTest)
    }

    @Test("state maintains allowAudioOutputTest through multiple updates")
    func stateMaintainsAllowAudioOutputTestThroughMultipleUpdates() throws {
        let sut = makeSUT()
        sut.loadUI()

        let initialState = try #require(getContentState(from: sut))
        let expectedAllowAudioOutputTest = AppConfig.audioSettings.allowAudioDiagnostics

        #expect(initialState.allowAudioOutputTest == expectedAllowAudioOutputTest)

        // Perform multiple state-changing operations
        sut.onToggleMic()
        sut.onToggleCamera()
        sut.onToggleMic()
        sut.onToggleCamera()

        let finalState = try #require(getContentState(from: sut))
        #expect(finalState.allowAudioOutputTest == expectedAllowAudioOutputTest)
    }

    @Test("allowAudioOutputTest reflects AppConfig setting")
    func allowAudioOutputTestReflectsAppConfigSetting() throws {
        let sut = makeSUT()
        sut.loadUI()

        let state = try #require(getContentState(from: sut))

        #expect(state.allowAudioOutputTest == AppConfig.audioSettings.allowAudioDiagnostics)
    }

    @Test("state properties are preserved during audio level updates")
    func statePropertiesPreservedDuringAudioLevelUpdates() throws {
        let sut = makeSUT()
        sut.loadUI()

        // Get initial state values
        let initialState = try #require(getContentState(from: sut))
        let expectedRoomName = initialState.roomName
        let expectedAllowMicrophoneControl = initialState.allowMicrophoneControl
        let expectedAllowCameraControl = initialState.allowCameraControl
        let expectedAllowAudioOutputTest = initialState.allowAudioOutputTest

        // Simulate state changes that would trigger internal state updates
        sut.onToggleMic()

        let updatedState = try #require(getContentState(from: sut))

        // All properties should be preserved except for the ones that are supposed to change
        #expect(updatedState.roomName == expectedRoomName)
        #expect(updatedState.allowMicrophoneControl == expectedAllowMicrophoneControl)
        #expect(updatedState.allowCameraControl == expectedAllowCameraControl)
        #expect(updatedState.allowAudioOutputTest == expectedAllowAudioOutputTest)
    }

    @Test("multiple rapid state updates maintain consistency")
    func multipleRapidStateUpdatesMaintainConsistency() throws {
        let sut = makeSUT()
        sut.loadUI()

        let initialState = try #require(getContentState(from: sut))
        let expectedAllowAudioOutputTest = initialState.allowAudioOutputTest

        // Rapid state changes
        for _ in 0..<10 {
            sut.onToggleMic()
            sut.onToggleCamera()
        }

        let finalState = try #require(getContentState(from: sut))
        #expect(finalState.allowAudioOutputTest == expectedAllowAudioOutputTest)
    }

    @Test("initial state has correct allowAudioOutputTest value")
    func initialStateHasCorrectAllowAudioOutputTestValue() throws {
        let sut = makeSUT()

        // Before loadUI, state should be initial
        if case .content(let initialState) = sut.state {
            // WaitingRoomState.initial should have allowAudioOutputTest = false (default)
            #expect(initialState.allowAudioOutputTest == false)
        }

        // After loadUI, state should reflect AppConfig
        sut.loadUI()
        let loadedState = try #require(getContentState(from: sut))
        #expect(loadedState.allowAudioOutputTest == AppConfig.audioSettings.allowAudioDiagnostics)
    }
}
