//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import OpenTok
import SwiftUI
import VERACore

open class OpenTokPublisher: NSObject, VERAPublisher, OTPublisherKitDelegate {
    private(set) var otPublisher: OTPublisher
    var cancellables = Set<AnyCancellable>()

    let id = "publisherID"
    var stream: OTStream? { otPublisher.stream }
    let date = Date()
    var lastAudioLevelUpdate = Date.distantPast

    @Published public private(set) var isScreenshare: Bool = false
    @Published public private(set) var isPinned: Bool = false
    @Published public private(set) var audioLevel: Float = 0.0
    @Published public private(set) var videoDimensions = VideoDimensions.default
    @Published public private(set) var participant: Participant

    public var aspectRatio: Double { videoDimensions.aspectRatio }

    var onError: ((Error) -> Void)?

    public var view: AnyView {
        let view = otPublisher.view!
        let rendererView = UIViewContainer(view: view)
        return AnyView(rendererView)
    }

    public var publishAudio: Bool {
        get {
            otPublisher.publishAudio
        }
        set {
            otPublisher.publishAudio = newValue
        }
    }

    public var publishVideo: Bool {
        get {
            otPublisher.publishVideo
        }
        set {
            otPublisher.publishVideo = newValue
        }
    }

    public var cameraPosition: CameraPosition {
        get {
            otPublisher.cameraPosition == .front ? .front : .back
        }

        set {
            otPublisher.cameraPosition = newValue == .front ? .front : .back
        }
    }

    public init(publisher: OTPublisher) {
        otPublisher = publisher
        participant = Participant(
            id: id,
            name: publisher.stream?.name ?? "",
            isMicEnabled: otPublisher.publishAudio,
            isCameraEnabled: otPublisher.publishVideo,
            videoDimensions: VideoDimensions.default,
            isRemote: false,
            creationTime: date,
            audioLevel: 0,
            lastAudioLevelUpdate: lastAudioLevelUpdate,
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView()))
        super.init()
    }

    func setup() {
        stream?
            .publisher(for: \.videoDimensions)
            .removeDuplicates()
            .sink { [weak self] newSize in
                self?.videoDimensions = newSize
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        stream?
            .publisher(for: \.hasAudio)
            .removeDuplicates()
            .sink { [weak self] newSize in
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        stream?
            .publisher(for: \.hasVideo)
            .removeDuplicates()
            .sink { [weak self] newSize in
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        $audioLevel
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        updateParticipant()
    }

    private func updateParticipant() {
        participant = Participant(
            id: id,
            name: stream?.name ?? "",
            isMicEnabled: otPublisher.publishAudio,
            isCameraEnabled: otPublisher.publishVideo,
            videoDimensions: videoDimensions,
            creationTime: date,
            audioLevel: audioLevel,
            lastAudioLevelUpdate: lastAudioLevelUpdate,
            isScreenshare: isScreenshare,
            isPinned: isPinned,
            view: view
        )
    }

    public func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print(error.localizedDescription)
        onError?(error)
    }
}
