//
//  Created by Vonage on 15/7/25.
//

import Foundation
import OpenTok
import SwiftUI
import UIKit
import VERACore

public final class OpenTokPublisherFactory: PublisherFactory {

    enum Error: Swift.Error {
        case publisherInitializationFailed
    }

    public init() {
    }

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

extension VideoScaleBehavior {
    var otVideoScaleBehavior: OTVideoViewScaleBehavior {
        switch self {
        case .fill: return .fill
        case .fit: return .fit
        @unknown default: return .fill
        }
    }
}
