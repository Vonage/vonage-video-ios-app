//
//  Created by Vonage on 16/7/25.
//

import Foundation
import OpenTok
import SwiftUI
import VERACore

open class OpenTokPublisher: NSObject, VERAPublisher, OTPublisherKitDelegate {
    private(set) var otPublisher: OTPublisher

    var id: String { "publisherID" }
    var stream: OTStream? { otPublisher.stream }

    var onError: ((Error) -> Void)?

    public var videoDimensions: CGSize? { stream?.videoDimensions }

    public var aspectRatio: Double {
        guard let dimensions = videoDimensions,
            dimensions.width > 0 && dimensions.height > 0
        else {
            return 640.0 / 480.0
        }

        return Double(dimensions.width / dimensions.height)
    }

    var participant: Participant {
        Participant(
            id: id,
            name: stream?.name ?? "",
            isMicEnabled: otPublisher.publishAudio,
            isCameraEnabled: otPublisher.publishVideo,
            videoDimensions: videoDimensions,
            isRemote: false,
            view: view)
    }

    public var view: AnyView {
        let view = otPublisher.view!
        let rendererView = UIViewContainer(view: view)

        if aspectRatio >= 1 {
            otPublisher.viewScaleBehavior = .fill
        } else {
            otPublisher.viewScaleBehavior = .fit
        }

        return AnyView(rendererView)
    }

    public var publishAudio: Bool {
        get {
            otPublisher.publishAudio
        }
        set {
            otPublisher.publishAudio = newValue
        }
    }

    public var publishVideo: Bool {
        get {
            otPublisher.publishVideo
        }
        set {
            otPublisher.publishVideo = newValue
        }
    }

    public var cameraPosition: CameraPosition {
        get {
            otPublisher.cameraPosition == .front ? .front : .back
        }

        set {
            otPublisher.cameraPosition = newValue == .front ? .front : .back
        }
    }

    public init(publisher: OTPublisher) {
        otPublisher = publisher
    }

    public func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print(error.localizedDescription)
        onError?(error)
    }
}
