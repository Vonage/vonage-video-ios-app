//
//  Created by Vonage on 30/09/26.
//

import Combine
import SwiftUI
import Testing

@testable import VERAConfiguration
@testable import VERACore
@testable import VERADomain
@testable import VERATestHelpers

@MainActor
struct WaitingRoomViewModelFlagTests {

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

    // MARK: - Visibility flag mapping

    @Test("allowSettings reflects waitingRoomSettings.allowSettings from AppConfig")
    func allowSettingsReflectsAppConfig() throws {
        let sut = makeSUT()
        sut.loadUI()

        let state = try #require(getContentState(from: sut))
        #expect(state.allowSettings == AppConfig.waitingRoomSettings.allowSettings)
    }

    @Test("allowBackgroundEffects reflects videoSettings.allowBackgroundEffects from AppConfig")
    func allowBackgroundEffectsReflectsAppConfig() throws {
        let sut = makeSUT()
        sut.loadUI()

        let state = try #require(getContentState(from: sut))
        #expect(state.allowBackgroundEffects == AppConfig.videoSettings.allowBackgroundEffects)
    }

    @Test("allowAudioEffects reflects audioSettings.allowAdvancedNoiseSuppression from AppConfig")
    func allowAudioEffectsReflectsAppConfig() throws {
        let sut = makeSUT()
        sut.loadUI()

        let state = try #require(getContentState(from: sut))
        #expect(state.allowAudioEffects == AppConfig.audioSettings.allowAdvancedNoiseSuppression)
    }

    // MARK: - allowVideoOnJoin / allowAudioOnJoin initial gate

    /// Once the preview publisher is ready, permissions are authorized and the mock publisher
    /// publishes both audio and video by default. The initial camera state must therefore match
    /// `allowVideoOnJoin` exactly: the gate cannot enable the camera when the flag is `false`,
    /// and leaves it enabled when the flag is `true`.
    @Test("Initial camera state equals allowVideoOnJoin once the publisher is ready")
    func initialCameraStateGatedByAllowVideoOnJoin() async throws {
        let sut = makeSUT()
        sut.loadUI()
        await delay()

        let state = try #require(getContentState(from: sut))
        #expect(state.isCameraEnabled == AppConfig.videoSettings.allowVideoOnJoin)
    }

    @Test("Initial microphone state equals allowAudioOnJoin once the publisher is ready")
    func initialMicrophoneStateGatedByAllowAudioOnJoin() async throws {
        let sut = makeSUT()
        sut.loadUI()
        await delay()

        let state = try #require(getContentState(from: sut))
        #expect(state.isMicrophoneEnabled == AppConfig.audioSettings.allowAudioOnJoin)
    }

    // MARK: - Control button visibility (control AND onJoin)

    @Test("Microphone button visibility requires allowMicrophoneControl AND allowAudioOnJoin")
    func microphoneButtonVisibilityRequiresBothFlags() throws {
        let sut = makeSUT()
        sut.loadUI()

        let state = try #require(getContentState(from: sut))
        #expect(
            state.allowMicrophoneControl
                == (AppConfig.audioSettings.allowMicrophoneControl && AppConfig.audioSettings.allowAudioOnJoin))
    }

    @Test("Camera button visibility requires allowCameraControl AND allowVideoOnJoin")
    func cameraButtonVisibilityRequiresBothFlags() throws {
        let sut = makeSUT()
        sut.loadUI()

        let state = try #require(getContentState(from: sut))
        #expect(
            state.allowCameraControl
                == (AppConfig.videoSettings.allowCameraControl && AppConfig.videoSettings.allowVideoOnJoin))
    }
}
