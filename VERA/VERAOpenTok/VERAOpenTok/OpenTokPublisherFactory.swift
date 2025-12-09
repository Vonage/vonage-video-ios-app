//
//  Created by Vonage on 15/7/25.
//

import Foundation
import OpenTok
import SwiftUI
import UIKit
import VERACore

/// Creates configured `OpenTokPublisher` instances from `PublisherSettings`.
///
/// Encapsulates `OTPublisher` setup (display name, initial audio/video state,
/// and view scale behavior) and wraps it in ``OpenTokPublisher`` conforming to
/// ``VERAPublisher``.
///
/// - SeeAlso: ``OpenTokPublisher``, ``VERAPublisher``, ``PublisherSettings``
public final class OpenTokPublisherFactory: PublisherFactory {

    /// Errors that can occur while creating an OpenTok publisher.
    enum Error: Swift.Error {
        /// The underlying `OTPublisher` failed to initialize.
        case publisherInitializationFailed
    }

    /// Creates a new `OpenTokPublisherFactory`.
    public init() {}

    /// Builds a `VERAPublisher` backed by `OpenTokPublisher`.
    ///
    /// Configures:
    /// - `OTPublisherSettings.name` from `settings.username`
    /// - `publishAudio` and `publishVideo` according to `settings`
    /// - `viewScaleBehavior` using ``VideoScaleBehavior/otVideoScaleBehavior``
    ///
    /// The created ``OpenTokPublisher`` is assigned as the delegate of the underlying
    /// `OTPublisher` to receive OpenTok callbacks.
    ///
    /// - Parameter settings: Desired publisher configuration.
    /// - Returns: A configured publisher conforming to ``VERAPublisher``.
    /// - Throws: ``OpenTokPublisherFactory/Error/publisherInitializationFailed`` if `OTPublisher` could not be created.
    /// - Important: This does not automatically start publishing to the session; attach and start via the session wrapper.
    public func make(_ settings: PublisherSettings) throws -> any VERAPublisher {
        let publisherSettings = OTPublisherSettings()
        publisherSettings.name = settings.username

        guard let otPublisher = OTPublisher(delegate: nil, settings: publisherSettings) else {
            throw Error.publisherInitializationFailed
        }
        otPublisher.publishAudio = settings.publishAudio
        otPublisher.publishVideo = settings.publishVideo
        otPublisher.viewScaleBehavior = settings.scaleBehavior.otVideoScaleBehavior
        let publisher = OpenTokPublisher(publisher: otPublisher)
        otPublisher.delegate = publisher
        return publisher
    }
}

/// Maps app `VideoScaleBehavior` to OpenTok `OTVideoViewScaleBehavior`.
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
