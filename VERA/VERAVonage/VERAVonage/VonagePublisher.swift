//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import OpenTok
import SwiftUI
import VERACore
import VERADomain

/// A wrapper around `OTPublisher` that exposes a Swift-friendly API and reactive state.
///
/// `VonagePublisher` manages the local media stream published into an Vonage session.
/// It provides a SwiftUI-compatible `view`, emits reactive updates for media and participant
/// It provides a SwiftUI-compatible `view`, emits reactive updates for media and participant
/// state, and forwards Vonage publisher delegate callbacks through closures.
///
/// ## Overview
///
/// Use this class to:
/// - Control local audio/video publishing (`publishAudio`, `publishVideo`)
/// - Switch camera position (`cameraPosition`, ``switchCamera(to:)``)
/// - Access a SwiftUI view for rendering (`view`)
/// - Observe stream properties with Combine (video dimensions, participant model)
/// - Handle publisher lifecycle events and errors
///
/// It also maintains a `Participant` representation of the local publisher for consistent
/// UI and domain integration across the app.
open class VonagePublisher: NSObject, VERAPublisher, OTPublisherKitDelegate {
    /// The underlying Vonage publisher.
    public let otPublisher: OTPublisher
    /// The class that will create the transformer instances
    public let transformerFactory: VERATransformerFactory

    /// Internal subscription storage for Combine pipelines.
    var cancellables = Set<AnyCancellable>()

    /// A stable identifier for the local publisher participant.
    let id = "publisherID"

    /// A SwiftUI-compatible view rendering the publisher’s video.
    ///
    /// Wraps the underlying `UIView` from `OTPublisher` in a SwiftUI container so that
    /// publisher video can be embedded in SwiftUI layouts.
    public var view: AnyView {
        AnyView(UIViewContainer(view: otPublisher.view!))
    }

    /// The underlying Vonage stream once publishing starts, otherwise `nil`.
    var stream: OTStream? { otPublisher.stream }

    /// Creation timestamp of this publisher wrapper.
    let date = Date()

    /// Whether the publisher is currently sharing the screen.
    @Published public private(set) var isScreenshare: Bool = false
    /// Whether this publisher is pinned in the UI.
    @Published public private(set) var isPinned: Bool = false
    /// Current audio level [0.0, 1.0]; reactive property for UI bindings.
    @Published public private(set) var audioLevel: Float = 0.0
    /// Current video dimensions; reactive for layout and aspect ratio updates.
    @Published public private(set) var videoDimensions = VideoDimensions.initial
    /// The participant model representing the local publisher; kept in sync with stream and settings.
    @Published public private(set) var participant: Participant
    /// Whether the publisher had video enabled before entering hold state.
    @Published public private(set) var wasPublishingVideo: Bool = false
    /// Whether the publisher had audio enabled before entering hold state.
    @Published public private(set) var wasPublishingAudio: Bool = false
    /// Whether the publisher is currently on hold.
    @Published public private(set) var isOnHold: Bool = false
    /// Holds the current list of video transformers.
    @Published open private(set) var videoTransformers: [VERATransformer] = []

    /// Convenience for `videoDimensions.aspectRatio`.
    public var aspectRatio: Double { videoDimensions.aspectRatio }

    /// `true` when the publisher is attached to a session.
    public var hasSession: Bool { otPublisher.session != nil }

    /// Called when the publisher’s stream is created.
    var onStreamCreated: (() -> Void)?
    /// Called when the publisher’s stream is destroyed.
    var onStreamDestroyed: (() -> Void)?
    /// Called when the publisher encounters an error.
    var onError: ((Error) -> Void)?

    /// Controls local audio publishing.
    ///
    /// - Note: Toggling this affects what remote participants hear.
    public var publishAudio: Bool {
        get { otPublisher.publishAudio }
        set { otPublisher.publishAudio = newValue }
    }

    /// Controls local video publishing.
    ///
    /// - Note: Toggling this affects what remote participants see.
    public var publishVideo: Bool {
        get { otPublisher.publishVideo }
        set { otPublisher.publishVideo = newValue }
    }

    /// Current camera position (front/back).
    ///
    /// Maps Vonage’s camera position to the app’s `CameraPosition` abstraction.
    public var cameraPosition: CameraPosition {
        get { otPublisher.cameraPosition == .front ? .front : .back }
        set { otPublisher.cameraPosition = newValue == .front ? .front : .back }
    }

    /// Switches camera to a specific device by ID.
    ///
    /// - Parameter cameraDeviceID: One of the known `VonageCameraDevice` raw values.
    public func switchCamera(to cameraDeviceID: String) {
        switch cameraDeviceID {
        case VonageCameraDevice.front.rawValue:
            otPublisher.cameraPosition = .front
        case VonageCameraDevice.back.rawValue:
            otPublisher.cameraPosition = .back
        default:
            break
        }
    }

    /// Current scale behaviour.
    ///
    /// Maps Vonage’s view scale behavior to the app’s `VideoScaleBehavior` abstraction.
    public var scaleBehavior: VideoScaleBehavior {
        get { otPublisher.viewScaleBehavior == .fit ? .fit : .fill }
        set { otPublisher.viewScaleBehavior = newValue == .fit ? .fit : .fill }
    }

    /// Creates a new publisher wrapper.
    ///
    /// - Parameter publisher: The configured `OTPublisher` to wrap.
    public init(
        publisher: OTPublisher,
        transformerFactory: VERATransformerFactory
    ) {
        otPublisher = publisher
        self.transformerFactory = transformerFactory
        participant = Participant(
            id: id,
            name: publisher.stream?.name ?? "",
            isMicEnabled: otPublisher.publishAudio,
            isCameraEnabled: otPublisher.publishVideo,
            videoDimensions: VideoDimensions.initial,
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

    /// Sets up reactive observation of stream properties and updates the participant model.
    ///
    /// Observes `videoDimensions`, `hasAudio`, and `hasVideo` from the underlying stream
    /// and keeps the `participant` in sync. Also binds `audioLevel` updates to reflect on the model.
    ///
    /// - Important: Call after the publisher has a stream to ensure KVO publishers are available.
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
            .sink { [weak self] _ in
                self?.updateParticipant()
            }
            .store(in: &cancellables)

        stream?
            .publisher(for: \.hasVideo)
            .removeDuplicates()
            .sink { [weak self] _ in
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

    /// Rebuilds the participant model from current publisher and stream state.
    ///
    /// Keeps `participant` synchronized with `publishAudio`, `publishVideo`,
    /// `videoDimensions`, and the rendered `view`.
    func updateParticipant() {
        participant = Participant(
            id: id,
            connectionId: stream?.connection.connectionId,
            name: stream?.name ?? "",
            isMicEnabled: otPublisher.publishAudio,
            isCameraEnabled: otPublisher.publishVideo,
            videoDimensions: videoDimensions,
            isRemote: false,
            creationTime: date,
            isScreenshare: isScreenshare,
            isPinned: isPinned,
            view: view)
    }

    /// Sets or clears hold mode on the publisher.
    ///
    /// When entering hold, current audio/video states are remembered and disabled.
    /// When leaving hold, previous states are restored.
    ///
    /// - Parameter isOnHold: `true` to enter hold, `false` to resume previous states.
    public func setOnHold(_ isOnHold: Bool) {
        if isOnHold {
            wasPublishingAudio = otPublisher.publishAudio
            wasPublishingVideo = otPublisher.publishVideo
            otPublisher.publishAudio = false
            otPublisher.publishVideo = false
        } else {
            otPublisher.publishAudio = wasPublishingAudio
            otPublisher.publishVideo = wasPublishingVideo
        }
        self.isOnHold = isOnHold
    }

    /// Cleans up Combine subscriptions and clears callbacks.
    ///
    /// Also replaces the participant’s `view` with an empty placeholder to release UI resources.
    open func cleanUp() {
        participant = participant.withEmptyView

        cancellables.removeAll()

        onStreamCreated = nil
        onStreamDestroyed = nil
        onError = nil
    }

    // MARK: OTPublisherKitDelegate

    /// Vonage publisher delegate callback for errors.
    ///
    /// Forwards the error to ``onError`` for external handling.
    public func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        onError?(error)
    }

    /// Vonage publisher delegate callback when the stream is created.
    ///
    /// Use to trigger post-publish actions, like informing the call façade.
    public func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        onStreamCreated?()
    }

    /// Vonage publisher delegate callback when the stream is destroyed.
    ///
    /// Use to trigger teardown or UI updates.
    public func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        onStreamDestroyed?()
    }

    // MARK: Transformers

    /// Vonage publisher method for adding video transformers
    ///
    /// Used to apply video effects to the publishing and rendering.
    public func addVideoTransformer(_ transformer: VERATransformer) {
        videoTransformers.removeAll { $0.key == transformer.key }
        videoTransformers.append(transformer)

        updateVideoTransformers()
    }

    /// Vonage publisher method for setting video transformers
    ///
    /// Used to apply video effects to the publishing and rendering.
    open func setVideoTransformers(_ transformers: [any VERATransformer]) {
        videoTransformers = transformers

        updateVideoTransformers()
    }

    /// Vonage publisher method for removing a video transformer
    ///
    /// Used to removed a previously added transformer, does nothing if the key doesn't match with any transformer.
    public func removeTransformer(_ key: String) {
        videoTransformers.removeAll { $0.key == key }

        updateVideoTransformers()
    }

    open func updateVideoTransformers() {
        otPublisher.videoTransformers = videoTransformers.map(\.transformer)
        updateParticipant()
    }

    // MARK: Captions

    func enableCaptions() {
        otPublisher.publishCaptions = true
    }

    func disableCaptions() {
        otPublisher.publishCaptions = false
    }
}
