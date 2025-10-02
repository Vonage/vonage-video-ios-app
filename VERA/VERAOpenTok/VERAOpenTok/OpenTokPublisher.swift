//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import OpenTok
import SwiftUI
import VERACore

open class OpenTokPublisher: NSObject, VERAPublisher, OTPublisherKitDelegate {
    let otPublisher: OTPublisher
    var cancellables = Set<AnyCancellable>()

    let id = "publisherID"
    public var view: AnyView {
        AnyView(UIViewContainer(view: otPublisher.view!))
    }
    var stream: OTStream? { otPublisher.stream }
    let date = Date()

    @Published public private(set) var isScreenshare: Bool = false
    @Published public private(set) var isPinned: Bool = false
    @Published public private(set) var audioLevel: Float = 0.0
    @Published public private(set) var videoDimensions = VideoDimensions.default
    @Published public private(set) var participant: Participant

    public var aspectRatio: Double { videoDimensions.aspectRatio }
    public var hasSession: Bool { otPublisher.session != nil }

    var onStreamCreated: (() -> Void)?
    var onStreamDestroyed: (() -> Void)?
    var onError: ((Error) -> Void)?

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
            isScreenshare: false,
            isPinned: false,
            view: AnyView(UIViewContainer(view: publisher.view!)))
        super.init()
    }

    deinit {
        cleanUp()
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
            .sink { [weak self] audioLevel in
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
            isScreenshare: isScreenshare,
            isPinned: isPinned,
            view: view)
    }

    public func cleanUp() {
        participant = participant.withEmptyView

        cancellables.removeAll()

        onStreamCreated = nil
        onStreamDestroyed = nil
        onError = nil
    }

    public func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        onError?(error)
    }

    public func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        onStreamCreated?()
    }

    public func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        onStreamDestroyed?()
    }
}
