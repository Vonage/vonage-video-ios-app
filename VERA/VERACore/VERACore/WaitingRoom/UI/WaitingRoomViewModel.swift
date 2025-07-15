//
//  Created by Vonage on 15/7/25.
//

import Combine
import Foundation

public typealias WaitingRoomError = String

public enum WaitingRoomViewState: Equatable {
    case loading
    case error(WaitingRoomError)
    case success(RoomName)
    case content(WaitingRoomState)
}

public final class WaitingRoomViewModel: ObservableObject {
    @Published public var state: WaitingRoomViewState = .content(WaitingRoomState.default)
    @Published public var userName: String = ""
    @Published var publisherVideoView: PublisherVideoView = PublisherVideoView(videoView: nil)
    private let roomName: RoomName
    var publisher: VERAPublisher?

    private let createPublisherUseCase: CreatePublisherUseCase

    init(roomName: RoomName, createPublisherUseCase: CreatePublisherUseCase) {
        self.roomName = roomName
        self.state = .content(WaitingRoomState.default)
        self.createPublisherUseCase = createPublisherUseCase
    }

    func loadUI() {
        do {
            publisher = try createPublisherUseCase.invoke()
            if let publisher = publisher {
                publisherVideoView = PublisherVideoView(videoView: publisher.view)

                buildContentUiState(roomName: roomName, publisher: publisher)
            }
        } catch {
            print("Error: \(error)")
        }
    }

    func onMicToggle() {
        guard var publisher else { return }
        publisher.publishAudio.toggle()
        buildContentUiState(roomName: roomName, publisher: publisher)
    }

    func onCameraToggle() {
        guard var publisher else { return }
        publisher.publishVideo.toggle()
        buildContentUiState(roomName: roomName, publisher: publisher)
    }

    private func buildContentUiState(roomName: String, publisher: VERAPublisher) {
        state = .content(
            .init(
                roomName: roomName,
                isMicrophoneEnabled: publisher.publishAudio,
                isCameraEnabled: publisher.publishVideo,
                audioDevices: [],
                cameras: []))
    }
}
