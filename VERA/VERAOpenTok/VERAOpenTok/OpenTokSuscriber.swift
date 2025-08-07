//
//  Created by Vonage on 28/7/25.
//

import Foundation
import OpenTok
import SwiftUI
import VERACore

public class OpenTokSuscriber: NSObject {
    let otSuscriber: OTSubscriber

    var id: String { stream.streamId }
    var stream: OTStream { otSuscriber.stream! }

    public var videoDimensions: CGSize? { stream.videoDimensions }

    public var aspectRatio: Double {
        guard let dimensions = videoDimensions,
              dimensions.width > 0 && dimensions.height > 0 else {
            return 640.0 / 480.0
        }
        return Double(dimensions.width / dimensions.height)
    }
    
    var participant: Participant {
        Participant(
            id: stream.streamId,
            name: stream.name ?? "",
            isMicEnabled: stream.hasAudio,
            isCameraEnabled: stream.hasVideo,
            videoDimensions: videoDimensions,
            view: view)
    }

    public var view: AnyView {
        let view = otSuscriber.view!
        let rendererView = UIViewContainer(view: view)
        otSuscriber.viewScaleBehavior = .fit
        
        return AnyView(
            rendererView
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()
        )
    }

    init(suscriber: OTSubscriber) {
        otSuscriber = suscriber
    }
}

extension OpenTokSuscriber: OTSubscriberDelegate {
    // MARK: - Suscriber delegate

    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {

    }

    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {

    }
}

extension OpenTokSuscriber: OTSubscriberKitAudioLevelDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, audioLevelUpdated audioLevel: Float) {

    }
}

extension OpenTokSuscriber: OTSubscriberKitCaptionsDelegate {
    // MARK: Audio levels delegate

    public func subscriber(_ subscriber: OTSubscriberKit, caption text: String, isFinal: Bool) {

    }
}

extension CGSize {
    var aspectRatio: CGFloat {
        width / height
    }
}
