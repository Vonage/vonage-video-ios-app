//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERATestHelpers

@testable import VERACore

@Suite("Waiting room view model tests")
struct WaitingRoomViewModelTests {

    // MARK: - Initial State Tests

    @Test("Given initial state, when view model is created, then state should be the default one")
    func initialStateShouldBeDefaultContent() {
        let sut = makeSUT()

        #expect(sut.state == .content(WaitingRoomState.default))
    }

    @Test("Given initial room name, the content state should have the same room name")
    func loadUIShouldHaveSameRoomName() async {
        let expectedRoomName = "Another room"
        let sut = makeSUT(roomName: expectedRoomName)

        sut.loadUI()

        switch sut.state {
        case .content(let state):
            #expect(state.roomName == expectedRoomName)
        default:
            Issue.record("Expected content with expected devices")
        }
    }

    @Test(
        "Given initial state, when view model is loaded, if no devices are injected then no devices are going to be available"
    )
    func loadUIShouldNotLoadAvailableDevices() {
        let sut = makeSUT()

        #expect(sut.state == .content(WaitingRoomState.default))

        sut.loadUI()

        switch sut.state {
        case .content(let state):
            #expect(state.audioDevices == [])
            #expect(state.cameras == [])
        default:
            Issue.record("Expected content with expected devices")
        }
    }

    @Test("Given initial state, when view model is loaded, then audio devices are available")
    func loadUIShouldLoadAvailableAudioDevices() async throws {
        let audioDevicesRepository = makeMockAudioDevicesRepository()
        let cameraDevicesRepository = makeMockCameraDevicesRepository()

        let audioDevices = [
            AudioDevice(id: "an id", name: "a name", portDescription: "a port description"),
            AudioDevice(id: "another id", name: "another name", portDescription: "another port description"),
        ]
        audioDevicesRepository.set(audioDevices)

        let sut = makeSUT(
            audioDevicesRepository: audioDevicesRepository,
            cameraDevicesRepository: cameraDevicesRepository
        )

        #expect(sut.state == .content(WaitingRoomState.default))

        sut.loadUI()

        let expectedAudioDevices = [
            UIAudioDevice(id: "an id", name: "a name", iconName: "a port description"),
            UIAudioDevice(id: "another id", name: "another name", iconName: "another port description"),
        ]

        await delay()

        switch sut.state {
        case .content(let contentState):
            #expect(contentState.audioDevices == expectedAudioDevices)
        default:
            Issue.record("Expected non empty audio devices, got: \(sut.state)")
        }
    }

    @Test("Given initial state, when view model is loaded, then camera devices are available")
    func loadUIShouldLoadAvailableCameraDevices() async throws {
        let audioDevicesRepository = makeMockAudioDevicesRepository()
        let cameraDevicesRepository = makeMockCameraDevicesRepository()

        let cameraDevices = [
            CameraDevice(id: "Front", name: "a name"),
            CameraDevice(id: "Back", name: "another name"),
        ]
        cameraDevicesRepository.set(cameraDevices)

        let sut = makeSUT(
            audioDevicesRepository: audioDevicesRepository,
            cameraDevicesRepository: cameraDevicesRepository
        )

        #expect(sut.state == .content(WaitingRoomState.default))

        sut.loadUI()

        let expectedCameraDevices = [
            UICameraDevice(id: "Front", name: "a name", iconName: "person.fill.viewfinder"),
            UICameraDevice(id: "Back", name: "another name", iconName: "iphone.rear.camera"),
        ]

        await delay()

        switch sut.state {
        case .content(let contentState):
            #expect(contentState.cameras == expectedCameraDevices)
        default:
            Issue.record("Expected non empty cameras, got: \(sut.state)")
        }
    }

    // MARK: SUT

    func makeSUT(
        roomName: RoomName = "heart-of-gold",
        publisherRepository: PublisherRepository = makeMockVERAPublisherRepository(),
        cameraPreviewProviderRepository: CameraPreviewProviderRepository = makeMockCameraPreviewProviderRepository(),
        audioDevicesRepository: AudioDevicesRepository = makeMockAudioDevicesRepository(),
        cameraDevicesRepository: CameraDevicesRepository = makeMockCameraDevicesRepository(),
        userRepository: UserRepository = makeMockUserRepository()
    ) -> WaitingRoomViewModel {
        WaitingRoomViewModel(
            roomName: roomName,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            audioDevicesRepository: audioDevicesRepository,
            cameraDevicesRepository: cameraDevicesRepository,
            selectAudioDeviceUseCase: .init(audioDevicesRepository: audioDevicesRepository),
            joinRoomUseCase: .init(
                userRepository: userRepository,
                cameraPreviewProviderRepository: cameraPreviewProviderRepository,
                publisherRepository: publisherRepository),
            requestMicrophonePermissionUseCase: .init(),
            requestCameraPermissionUseCase: .init(),
            checkCameraAuthorizationStatusUseCase: .init(),
            userRepository: userRepository)
    }
}
