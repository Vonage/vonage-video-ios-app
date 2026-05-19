//
//  Created by Vonage on 27/3/26.
//

import Combine
import SwiftUI
import VERADomain

/// A decorator around `VERAPublisher` that replaces `audioLevelPublisher`
/// with live microphone input via `MicVolumeListener`.
///
/// Used in the waiting room where the Vonage session is not connected,
/// so the SDK's audio-level delegate never fires.
/// All other protocol members forward to the wrapped publisher.
final class MicLevelPublisherDecorator: VERAPublisher {

    private let wrapped: VERAPublisher
    private let micVolumeListener = MicVolumeListener()
    private lazy var micPublisher: AnyPublisher<Float, Never> = micVolumeListener.start()

    init(wrapping publisher: VERAPublisher) {
        self.wrapped = publisher
    }

    deinit {
        micVolumeListener.stop()
    }

    // MARK: - Audio level (overridden)

    var audioLevelPublisher: AnyPublisher<Float, Never> { micPublisher }

    // MARK: - Forwarded properties

    var view: AnyView { wrapped.view }

    var publishAudio: Bool {
        get { wrapped.publishAudio }
        set { wrapped.publishAudio = newValue }
    }

    var publishVideo: Bool {
        get { wrapped.publishVideo }
        set { wrapped.publishVideo = newValue }
    }

    var cameraPosition: CameraPosition {
        get { wrapped.cameraPosition }
        set { wrapped.cameraPosition = newValue }
    }

    var videoTransformers: [VERATransformer] { wrapped.videoTransformers }
    var audioTransformers: [VERATransformer] { wrapped.audioTransformers }
    var transformerFactory: VERATransformerFactory { wrapped.transformerFactory }

    // MARK: - Forwarded methods

    func switchCamera(to cameraDeviceID: String) { wrapped.switchCamera(to: cameraDeviceID) }

    func cleanUp() {
        micVolumeListener.stop()
        wrapped.cleanUp()
    }

    func addVideoTransformer(_ transformer: VERATransformer) { wrapped.addVideoTransformer(transformer) }
    func setVideoTransformers(_ transformers: [VERATransformer]) { wrapped.setVideoTransformers(transformers) }
    func removeTransformer(_ key: String) { wrapped.removeTransformer(key) }

    func addAudioTransformer(_ transformer: VERATransformer) { wrapped.addAudioTransformer(transformer) }
    func setAudioTransformers(_ transformers: [VERATransformer]) { wrapped.setAudioTransformers(transformers) }
    func removeAudioTransformer(_ key: String) { wrapped.removeAudioTransformer(key) }
}
