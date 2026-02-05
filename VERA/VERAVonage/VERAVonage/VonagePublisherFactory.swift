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
        let publisherSettings = OTPublisherSettings()
        publisherSettings.name = settings.username

        guard let otPublisher = OTPublisher(delegate: nil, settings: publisherSettings) else {
            throw Error.publisherInitializationFailed
        }
        otPublisher.publishAudio = settings.publishAudio && checkMicrophoneAuthorizationStatusUseCase().isAuthorized
        otPublisher.publishVideo = settings.publishVideo && checkCameraAuthorizationStatusUseCase().isAuthorized
        otPublisher.viewScaleBehavior = settings.scaleBehavior.otVideoScaleBehavior
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
