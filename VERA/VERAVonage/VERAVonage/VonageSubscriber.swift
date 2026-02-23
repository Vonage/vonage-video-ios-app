//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import SwiftUI
import VERACore
import VERADomain

/// Constants used for video subscription management.
private enum SubscriberConstants {
    /// Delay before disabling video when a participant becomes hidden.
    ///
    /// This debounce interval prevents video flickering during rapid layout transitions
    /// (e.g., when a participant moves between visible and hidden states).
    /// The delay allows `onAppear` to cancel the disable task if the participant
    /// reappears in a different view within this timeframe.
    ///
    /// - Note: 500ms balances responsiveness with transition handling.
    static let videoDisableDebounceNanoseconds = 500
}

/// A wrapper around `OTSubscriber` that exposes reactive state, a SwiftUI view, and bandwidth controls.
///
/// `VonageSubscriber` represents a single remote participant’s media stream. It provides a SwiftUI-compatible view,
/// publishes Combine signals for stream properties, and implements visibility-driven subscription to conserve bandwidth.
///
/// ## Overview
///
/// Use this class to:
/// - Render remote video via a SwiftUI-compatible `view` (through the `Participant` model)
/// - Observe audio level, video dimensions, and participant state with Combine
/// - Enable/disable video subscription based on on-screen visibility
/// - Enter/exit hold mode to pause/resume media subscription
/// - Handle Vonage subscriber delegate callbacks (connect, errors, audio levels, captions)
///
/// ## Bandwidth Optimization
///
/// This subscriber leverages visibility-driven subscription:
/// - When the participant’s view appears on screen, video subscription is enabled
/// - When the participant’s view disappears, video subscription is disabled
/// - A delayed reinforcement re-enables video a short time after appear to stabilize during UI transitions
///
/// Visibility changes are wired via the associated ``Participant``’s `onAppear` and `onDisappear` handlers.
public class VonageSubscriber: NSObject {
    /// The underlying Vonage subscriber.
    let otSubscriber: OTSubscriber

    /// Internal subscription storage for Combine pipelines.
    private var cancellables = Set<AnyCancellable>()

    /// Tracks audio levels using a log-moving average for smoother UI.
    private let movingAvgAudioLevelTracker = MovingAvgAudioLevelTracker()

    /// Stable identifier for the remote stream.
    let id: String
    /// The stream’s display name if available.
    var name: String { otSubscriber.stream?.name ?? "" }
    /// The underlying Vonage stream.
    private let stream: OTStream
    /// The stream’s creation timestamp.
    var date: Date { stream.creationTime }

    /// True once the subscriber is connected; prevents premature subscription toggles.
    @Atomic private var subscriberDidConnect = false

    /// Called when the subscriber encounters an error.
    var onError: (() -> Void)?

    /// Called when a caption is received
    var onCaption: ((VonageCaption) -> Void)?

    /// Called when the subscriber connects
    var onConnected: (() -> Void)? = {}

    /// Whether the stream represents a screen share.
    @Published public private(set) var isScreenshare: Bool = false
    /// Whether this subscriber is pinned in the UI.
    @Published public private(set) var isPinned: Bool = false
    /// Current audio level [0.0, 1.0], smoothed by a log-moving average.
    @Published public private(set) var audioLevel: Float = 0.0
    /// Current video dimensions; reactive for layout and aspect ratio updates.
    @Published public private(set) var videoDimensions = VideoDimensions.initial
    /// The participant model representing this remote subscriber; kept in sync with stream properties.
    @Published public private(set) var participant: Participant
    /// Whether video was subscribed before entering hold.
    @Published public private(set) var wasSubscribedToVideo: Bool = false
    /// Whether audio was subscribed before entering hold.
    @Published public private(set) var wasSubscribedToAudio: Bool = false

    /// Tracks the number of views currently displaying this participant.
    /// Video is enabled when count > 0 and disabled when count reaches 0.
    @Atomic private var visibilityCount: Int = 0

    /// A delayed task that disables video subscription after visibility changes.
    /// Uses debouncing to handle rapid layout transitions gracefully.
    private var disableTask: Task<Void, Never>?

    /// Convenience for `videoDimensions.aspectRatio`.
    public var aspectRatio: Double { videoDimensions.aspectRatio }

    /// Creates a new subscriber wrapper.
    ///
    /// - Parameter subscriber: The configured `OTSubscriber` to wrap.
    init(subscriber: OTSubscriber) {
        otSubscriber = subscriber
        let stream = subscriber.stream!
        self.stream = stream
        id = stream.streamId
        isScreenshare = stream.videoType == .screen
        participant = Participant(
            id: stream.streamId,
            connectionId: stream.connection.connectionId,
            name: stream.name ?? "",
            isMicEnabled: stream.hasAudio,
            isCameraEnabled: stream.hasVideo,
            videoDimensions: VideoDimensions.initial,
            creationTime: stream.creationTime,
            isScreenshare: stream.videoType == .screen,
            isPinned: false,
            view: AnyView(UIViewContainer(view: subscriber.view!)))
        super.init()
    }

    deinit {
        cleanUp()
    }

    /// Sets up reactive observation of stream properties and updates the participant model.
    ///
    /// - Important: Call after the subscriber has a stream to ensure KVO publishers are available.
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

    /// Rebuilds the participant model from current stream state and wires visibility handlers.
    ///
    /// Visibility-driven subscription:
    /// - `onAppear`: Enables video subscription and schedules a delayed reinforcement
    /// - `onDisappear`: Disables video subscription
    private func updateParticipant() {
        let name = stream.name ?? ""
        participant = Participant(
            id: id,
            connectionId: stream.connection.connectionId,
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
            self.visibilityCount += 1
            self.disableTask?.cancel()
            if self.visibilityCount > 0 {
                self.setActiveSubscription(true)
            }
        }

        participant.onDisappear = { [weak self] in
            guard let self else { return }
            self.visibilityCount = max(0, self.visibilityCount - 1)
            self.disableTask?.cancel()
            self.disableTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(SubscriberConstants.videoDisableDebounceNanoseconds))
                guard let self, !Task.isCancelled, self.visibilityCount <= 0 else { return }
                self.setActiveSubscription(false)
            }
        }
    }

    /// Enables or disables the video subscription based on visibility.
    ///
    /// - Parameter visible: `true` to subscribe to video; `false` to unsubscribe.
    ///
    /// - Important: No-ops until the subscriber is connected to avoid SDK limitations.
    private func setActiveSubscription(_ visible: Bool) {
        // Do not attempt to unsubscribe video before the subscriber did connect
        // it will result in an inability to modify the video subscription later
        guard subscriberDidConnect else { return }

        otSubscriber.subscribeToVideo = visible
    }

    /// Enables or disables audio subscription.
    ///
    /// - Parameter enabled: `true` to subscribe to audio; `false` to unsubscribe.
    func enableAudioSubscription(_ enabled: Bool) {
        otSubscriber.subscribeToAudio = enabled
    }

    /// Sets or clears hold mode on the subscriber.
    ///
    /// When entering hold, current audio/video subscription states are remembered and disabled.
    /// When leaving hold, previous states are restored.
    ///
    /// - Parameter isOnHold: `true` to enter hold; `false` to resume previous states.
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

    /// Cleans up Combine subscriptions, clears callbacks, and cancels reinforcement tasks.
    ///
    /// Also replaces the participant’s `view` with an empty placeholder to release UI resources.
    func cleanUp() {
        participant = participant.withEmptyView

        onError = nil
        onCaption = nil
        onConnected = nil

        cancellables.removeAll()

        participant.onAppear = nil
        participant.onDisappear = nil

        disableTask?.cancel()
        disableTask = nil
    }

    // MARK: Captions

    func enableCaptions() {
        otSubscriber.subscribeToCaptions = true
    }

    func disableCaptions() {
        otSubscriber.subscribeToCaptions = false
    }
}

// MARK: - OTSubscriberDelegate

extension VonageSubscriber: OTSubscriberDelegate {
    /// Vonage subscriber delegate callback when connection completes.
    ///
    /// Sets the `subscriberDidConnect` flag, enabling visibility-driven subscription changes,
    /// and refreshes the participant model.
    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        subscriberDidConnect = true

        updateParticipant()

        onConnected?()
    }

    /// Vonage subscriber delegate callback for errors.
    ///
    /// Forwards the error event to ``onError`` for external handling.
    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        onError?()
    }
}

// MARK: - OTSubscriberKitAudioLevelDelegate

extension VonageSubscriber: OTSubscriberKitAudioLevelDelegate {
    /// Vonage audio level delegate callback.
    ///
    /// Smooths the raw audio level via a log-moving average and publishes the result.
    public func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {
        let result = movingAvgAudioLevelTracker.track(audioLevel)
        self.audioLevel = round(result.logMovingAvg * 100) / 100
    }
}

// MARK: - OTSubscriberKitCaptionsDelegate

extension VonageSubscriber: OTSubscriberKitCaptionsDelegate {
    /// Vonage captions delegate callback.
    ///
    /// Receives live captions; implementation can be extended to publish captions to the UI.
    public func subscriber(_ subscriber: OTSubscriberKit, caption text: String, isFinal: Bool) {
        let name = subscriber.stream?.name
        let id = subscriber.stream?.streamId
        onCaption?(.init(id: id, name: name, text: text, isFinal: isFinal, isRemote: true))
    }
}
