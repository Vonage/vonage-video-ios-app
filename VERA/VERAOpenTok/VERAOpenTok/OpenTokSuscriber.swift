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

    lazy var participant: Participant = {
        Participant(
            id: stream.streamId,
            name: stream.name ?? "",
            isMicEnabled: stream.hasAudio,
            isCameraEnabled: stream.hasVideo,
            view: view)
    }()

    public lazy var view: AnyView = {
        let rendererView = UIViewContainer(view: otSuscriber.view!)
        return AnyView(rendererView)
    }()

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
