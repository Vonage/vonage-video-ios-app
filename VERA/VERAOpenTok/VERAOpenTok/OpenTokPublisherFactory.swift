//
//  Created by Vonage on 15/7/25.
//

import Foundation
import OpenTok
import SwiftUI
import UIKit
import VERACore

public final class OpenTokPublisherFactory: PublisherFactory {

    public init() {
    }

    @MainActor
    public func make(_ settings: PublisherSettings) async -> any VERAPublisher {
        let publisherSettings = OTPublisherSettings()
        publisherSettings.name = settings.username
        publisherSettings.audioTrack = settings.publishAudio
        publisherSettings.videoTrack = settings.publishVideo

        let otPublisher = OTPublisher(delegate: nil, settings: publisherSettings)!
        let publisher = OpenTokPublisher(publisher: otPublisher)
        otPublisher.delegate = publisher
        return publisher
    }
}
