//
//  Created by Vonage on 15/7/25.
//

import Foundation
import OpenTok
import SwiftUI
import UIKit
import VERACore
import VERADomain

/// Creates configured `VonagePublisher` instances from `PublisherSettings`.
///
/// Encapsulates `OTPublisher` setup (display name, initial audio/video state,
/// and view scale behavior) and wraps it in ``VonagePublisher`` conforming to
/// ``VERAPublisher``.
///
/// - SeeAlso: ``VonagePublisher``, ``VERAPublisher``, ``PublisherSettings``
public final class VonagePublisherFactory: PublisherFactory {

    /// Errors that can occur while creating an Vonage publisher.
    enum Error: Swift.Error {
        /// The underlying `OTPublisher` failed to initialize.
        case publisherInitializationFailed
    }

    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    private let checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase

    /// This factory returns the specific Vonage audio or video transformers
    lazy var vonageTransformerFactory = VonageTransformerFactory()

    /// Creates a new `VonagePublisherFactory`.
    public init(
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase,
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase
    ) {
        self.checkCameraAuthorizationStatusUseCase = checkCameraAuthorizationStatusUseCase
        self.checkMicrophoneAuthorizationStatusUseCase = checkMicrophoneAuthorizationStatusUseCase
    }

    /// Builds a `VERAPublisher` backed by `VonagePublisher`.
    ///
    /// Configures:
    /// - `OTPublisherSettings.name` from `settings.username`
    /// - `publishAudio` and `publishVideo` according to `settings`
    /// - `viewScaleBehavior` using ``VideoScaleBehavior/otVideoScaleBehavior``
    ///
    /// The created ``VonagePublisher`` is assigned as the delegate of the underlying
    /// `OTPublisher` to receive Vonage callbacks.
    ///
    /// - Parameter settings: Desired publisher configuration.
    /// - Returns: A configured publisher conforming to ``VERAPublisher``.
    /// - Throws: ``VonagePublisherFactory/Error/publisherInitializationFailed`` if `OTPublisher` could not be created.
    /// - Important: This does not automatically start publishing to the session; attach and start via the session wrapper.
    public func make(_ settings: PublisherSettings) throws -> any VERAPublisher {
        let otPublisher = try makeOTPublisher(settings)
        return wrapPublisher(otPublisher, settings: settings)
    }

    // MARK: - Private helpers

    /// Configures `OTPublisherSettings` and initialises `OTPublisher`.
    /// Does **not** touch UIKit — safe to call from a background thread.
    private func makeOTPublisher(_ settings: PublisherSettings) throws -> OTPublisher {
        let publisherSettings = OTPublisherSettings()
        publisherSettings.name = settings.username

        // All OTPublisherSettings properties must be set BEFORE OTPublisher is initialised.
        if let frameRate = settings.advancedSettings?.videoFrameRate?.otFrameRate {
            publisherSettings.cameraFrameRate = frameRate
        }
        if let resolution = settings.advancedSettings?.videoResolution?.otResolucion {
            publisherSettings.cameraResolution = resolution
        }
        if let maxAudioBitrate = settings.advancedSettings?.maxAudioBitrate {
            publisherSettings.audioBitrate = maxAudioBitrate
        }
        publisherSettings.subscriberAudioFallbackEnabled =
            settings.advancedSettings?.subscriberAudioFallbackEnabled ?? false
        publisherSettings.publisherAudioFallbackEnabled =
            settings.advancedSettings?.publisherAudioFallbackEnabled ?? false
        if let preferredVideoCodecs = settings.advancedSettings?.preferredVideoCodecs?.otCodecPreference {
            publisherSettings.videoCodecPreference = preferredVideoCodecs
        }

        guard let otPublisher = OTPublisher(delegate: nil, settings: publisherSettings) else {
            throw Error.publisherInitializationFailed
        }
        return otPublisher
    }

    /// Wraps an already-initialised `OTPublisher` in `VonagePublisher`.
    /// Accesses `otPublisher.view` (UIKit) — **must** be called on the main thread.
    private func wrapPublisher(_ otPublisher: OTPublisher, settings: PublisherSettings) -> VonagePublisher {
        otPublisher.publishAudio = settings.publishAudio && checkMicrophoneAuthorizationStatusUseCase().isAuthorized
        otPublisher.publishVideo = settings.publishVideo && checkCameraAuthorizationStatusUseCase().isAuthorized
        otPublisher.viewScaleBehavior = settings.scaleBehavior.otVideoScaleBehavior

        if let bitratePreset = settings.advancedSettings?.videoBitratePreset?.otBitratePreset, bitratePreset != .custom
        {
            otPublisher.videoBitratePreset = bitratePreset
        } else if let maxVideoBitrate = settings.advancedSettings?.maxVideoBitrate, maxVideoBitrate > 0 {
            otPublisher.maxVideoBitrate = maxVideoBitrate
        }

        let publisher = VonagePublisher(
            publisher: otPublisher,
            transformerFactory: vonageTransformerFactory)
        otPublisher.delegate = publisher
        return publisher
    }
}

/// Maps app `VideoScaleBehavior` to Vonage `OTVideoViewScaleBehavior`.
extension VideoScaleBehavior {
    /// Equivalent `OTVideoViewScaleBehavior` for the current app setting.
    var otVideoScaleBehavior: OTVideoViewScaleBehavior {
        switch self {
        case .fill: return .fill
        case .fit: return .fit
        @unknown default: return .fill
        }
    }
}
