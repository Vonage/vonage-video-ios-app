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

    public func make() -> VERAPublisher {
        let settings = OTPublisherSettings()
        settings.name = "iOS"
        settings.audioTrack = true
        settings.videoTrack = true

        let otPublisher = OTPublisher(delegate: nil, settings: settings)!
        let publisher = OpenTokPublisher(publisher: otPublisher)
        otPublisher.delegate = publisher
        return publisher
    }
}
