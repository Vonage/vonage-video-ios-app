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
        case failedToCreateOTPublisher
        case failedToCreatePublisher
    }

    public init() {
    }

    public func make() throws -> VERAPublisher {

        let settings = OTPublisherSettings()
        settings.name = "iOS"
        settings.audioTrack = true
        settings.videoTrack = true

        guard let otPublisher = OTPublisher(delegate: nil, settings: settings) else {
            throw Error.failedToCreateOTPublisher
        }
        guard let view = otPublisher.view else {
            throw Error.failedToCreatePublisher
        }

        let publisher = OpenTokPublisher(publisher: otPublisher)
        otPublisher.delegate = publisher
        return publisher
    }
}

public final class OpenTokPublisher: NSObject, VERAPublisher, OTPublisherKitDelegate {
    private var publisher: OTPublisher

    public var view: AnyView {
        let rendererView = OpenTokRendererView(publisher: publisher)
        return AnyView(rendererView)
    }

    public var publishAudio: Bool {
        get {
            publisher.publishAudio
        }
        set {
            publisher.publishAudio = newValue
        }
    }

    public var publishVideo: Bool {
        get {
            publisher.publishVideo
        }
        set {
            publisher.publishVideo = newValue
        }
    }

    init(publisher: OTPublisher) {
        self.publisher = publisher
    }

    public func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print(error.localizedDescription)
    }
}

struct OpenTokRendererView: UIViewRepresentable {
    private let publisher: OTPublisher

    init(publisher: OTPublisher) {
        self.publisher = publisher
    }

    func makeUIView(context: Context) -> UIView { publisher.view! }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
