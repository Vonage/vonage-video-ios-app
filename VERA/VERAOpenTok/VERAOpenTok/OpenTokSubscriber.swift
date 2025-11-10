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
    private var cancellables = Set<AnyCancellable>()
    private let movingAvgAudioLevelTracker = MovingAvgAudioLevelTracker()

    let id: String
    var name: String { otSubscriber.stream?.name ?? "" }
    private let stream: OTStream
    var date: Date { stream.creationTime }
    @Atomic private var subscriberDidConnect = false

    var onError: (() -> Void)?

    @Published public private(set) var isScreenshare: Bool = false
    @Published public private(set) var isPinned: Bool = false
    @Published public private(set) var audioLevel: Float = 0.0
    @Published public private(set) var videoDimensions = VideoDimensions.default
    @Published public private(set) var participant: Participant
    @Published public private(set) var wasSubscribedToVideo: Bool = false
    @Published public private(set) var wasSubscribedToAudio: Bool = false

    private var reinforcementTask: Task<Void, Never>?

    public var aspectRatio: Double { videoDimensions.aspectRatio }

    init(subscriber: OTSubscriber) {
        otSubscriber = subscriber
        let stream = subscriber.stream!
        self.stream = stream
        id = stream.streamId
        isScreenshare = stream.videoType == .screen
        participant = Participant(
            id: stream.streamId,
            name: stream.name ?? "",
            isMicEnabled: stream.hasAudio,
            isCameraEnabled: stream.hasVideo,
            videoDimensions: VideoDimensions.default,
            creationTime: stream.creationTime,
            isScreenshare: stream.videoType == .screen,
            isPinned: false,
            view: AnyView(UIViewContainer(view: subscriber.view!)))
        super.init()
    }

    deinit {
        cleanUp()
    }

    func setup() {
        otSubscriber.viewScaleBehavior = .fill

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
            .sink { [weak self] _ in
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        stream
            .publisher(for: \.hasVideo)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        updateParticipant()
    }

    private func updateParticipant() {
        let name = stream.name ?? ""
        participant = Participant(
            id: id,
            name: name,
            isMicEnabled: stream.hasAudio,
            isCameraEnabled: stream.hasVideo,
            videoDimensions: videoDimensions,
            creationTime: date,
            isScreenshare: isScreenshare,
            isPinned: isPinned,
            view: AnyView(UIViewContainer(view: otSubscriber.view!)))

        participant.onAppear = { [weak self] in
            guard let self else { return }
            self.setActiveSubscription(true)
            self.reinforcementTask?.cancel()

            self.reinforcementTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard let self, !Task.isCancelled else { return }
                self.setActiveSubscription(true)
            }
        }

        participant.onDisappear = { [weak self] in
            guard let self else { return }
            self.setActiveSubscription(false)
        }
    }

    private func setActiveSubscription(_ visible: Bool) {
        // Do not attempt to unsubscribe video before the subscriber did connect
        // it will result in an inability to modify the video subscription later
        guard subscriberDidConnect else { return }

        otSubscriber.subscribeToVideo = visible
    }

    public func setOnHold(_ isOnHold: Bool) {
        if isOnHold {
            wasSubscribedToAudio = otSubscriber.subscribeToAudio
            wasSubscribedToVideo = otSubscriber.subscribeToVideo
            otSubscriber.subscribeToAudio = false
            otSubscriber.subscribeToVideo = false
        } else {
            otSubscriber.subscribeToAudio = wasSubscribedToAudio
            otSubscriber.subscribeToVideo = wasSubscribedToVideo
        }
    }

    func cleanUp() {
        participant = participant.withEmptyView

        onError = nil

        cancellables.removeAll()

        participant.onAppear = nil
        participant.onDisappear = nil

        reinforcementTask?.cancel()
        reinforcementTask = nil
    }
}

extension OpenTokSubscriber: OTSubscriberDelegate {
    // MARK: - Subscriber delegate

    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        subscriberDidConnect = true

        updateParticipant()
    }

    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        onError?()
    }
}

extension OpenTokSubscriber: OTSubscriberKitAudioLevelDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        let result = movingAvgAudioLevelTracker.track(audioLevel)
        self.audioLevel = round(result.logMovingAvg * 100) / 100
    }
}

extension OpenTokSubscriber: OTSubscriberKitCaptionsDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, caption text: String, isFinal: Bool) {

    }
}
