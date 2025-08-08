//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import SwiftUI
import VERACore

public class OpenTokSubscriber: NSObject {
    let otSubscriber: OTSubscriber
    var cancellables = Set<AnyCancellable>()

    var id: String { stream.streamId }
    var stream: OTStream { otSubscriber.stream! }
    var date: Date { stream.creationTime }
    var lastAudioLevelUpdate = Date.distantPast

    @Published public private(set) var isScreenshare: Bool = false
    @Published public private(set) var isPinned: Bool = false
    @Published public private(set) var audioLevel: Float = 0.0
    @Published public private(set) var videoDimensions = VideoDimensions.default
    @Published public private(set) var participant: Participant

    public var aspectRatio: Double { videoDimensions.aspectRatio }

    public var view: AnyView {
        let view = otSubscriber.view!
        let rendererView = UIViewContainer(view: view)
        otSubscriber.viewScaleBehavior = .fill
        return AnyView(rendererView)
    }

    init(subscriber: OTSubscriber) {
        otSubscriber = subscriber
        participant = Participant(
            id: subscriber.stream!.streamId,
            name: subscriber.stream!.name ?? "",
            isMicEnabled: subscriber.stream!.hasAudio,
            isCameraEnabled: subscriber.stream!.hasVideo,
            videoDimensions: VideoDimensions.default,
            creationTime: subscriber.stream!.creationTime,
            audioLevel: 0,
            lastAudioLevelUpdate: lastAudioLevelUpdate,
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView()))
        super.init()
    }

    func setup() {
        stream
            .publisher(for: \.videoDimensions)
            .removeDuplicates()
            .sink { [weak self] newSize in
                self?.videoDimensions = newSize
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        stream
            .publisher(for: \.hasAudio)
            .removeDuplicates()
            .sink { [weak self] newSize in
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        stream
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
            name: stream.name ?? "",
            isMicEnabled: stream.hasAudio,
            isCameraEnabled: stream.hasVideo,
            videoDimensions: videoDimensions,
            creationTime: date,
            audioLevel: audioLevel,
            lastAudioLevelUpdate: lastAudioLevelUpdate,
            isScreenshare: isScreenshare,
            isPinned: isPinned,
            view: view)
    }
}

extension OpenTokSubscriber: OTSubscriberDelegate {
    // MARK: - Subscriber delegate

    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {

    }

    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {

    }
}

extension OpenTokSubscriber: OTSubscriberKitAudioLevelDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        self.lastAudioLevelUpdate = Date()
        self.audioLevel = audioLevel
    }
}

extension OpenTokSubscriber: OTSubscriberKitCaptionsDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, caption text: String, isFinal: Bool) {

    }
}
