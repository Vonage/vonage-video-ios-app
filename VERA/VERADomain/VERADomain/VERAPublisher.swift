//
//  Created by Vonage on 16/7/25.
//

import SwiftUI

/// The available camera positions for a publisher.
///
/// Use to control which physical camera is used for local video.
public enum CameraPosition {
    /// The device’s front-facing camera.
    case front
    /// The device’s back-facing camera.
    case back
}

/// A common interface for a media publisher used in the VERA app.
///
/// Conformers expose a SwiftUI-compatible `view` for rendering local video,
/// and controls for audio/video publishing and camera selection. This protocol
/// abstracts specific SDK implementations (e.g., Vonage) behind a stable API.
///
/// ## Responsibilities
/// - Provide a SwiftUI-compatible video view
/// - Expose audio/video publishing toggles
/// - Allow camera position changes or device-based switching
/// - Clean up resources when no longer needed
///
/// - SeeAlso: ``CameraPosition``
public protocol VERAPublisher: AnyObject {
    /// A SwiftUI-compatible view rendering the publisher’s video.
    ///
    /// Wraps the underlying platform view in `AnyView` to integrate with SwiftUI.
    var view: AnyView { get }

    /// Controls local audio publishing on/off.
    var publishAudio: Bool { get set }

    /// Controls local video publishing on/off.
    var publishVideo: Bool { get set }

    /// The current camera position (front/back).
    var cameraPosition: CameraPosition { get set }

    /// The current array of video transformers
    var videoTransformers: [VERATransformer] { get }

    /// The current array of audio transformers
    var audioTransformers: [VERATransformer] { get }

    var transformerFactory: VERATransformerFactory { get }

    /// Switches camera to a specific device by ID.
    ///
    /// - Parameter cameraDeviceID: A device identifier recognized by the underlying SDK.
    func switchCamera(to cameraDeviceID: String)

    /// Cleans up resources and detaches the publisher’s view.
    ///
    /// Implementations should release any retained resources and make the `view` safe to discard.
    func cleanUp()

    /// Adds a video transformer to the current publisher.
    func addVideoTransformer(_ transformer: VERATransformer)

    /// Sets a list video transformer to the current publisher.
    func setVideoTransformers(_ transformers: [VERATransformer])

    /// Removes a video transformer from the publisher
    func removeTransformer(_ key: String)

    /// Adds a audio transformer to the current publisher.
    func addAudioTransformer(_ transformer: VERATransformer)

    /// Sets a list audio transformer to the current publisher.
    func setAudioTransformers(_ transformers: [VERATransformer])

    /// Removes a audio transformer from the publisher
    func removeAudioTransformer(_ key: String)
}

public protocol VERATransformerFactory {
    func makeVideoTransformer(for key: String, params: String) throws -> VERATransformer
    func makeAudioTransformer(for key: String, params: String) throws -> VERATransformer
}

public protocol VERATransformer {
    var key: String { get }
    var transformer: AnyObject { get }
}
