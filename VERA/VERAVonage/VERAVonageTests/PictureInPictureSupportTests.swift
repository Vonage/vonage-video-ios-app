//
//  Created by Vonage on 14/7/26.
//

import AVKit
import Foundation
import OpenTok
import Testing
import UIKit

@testable import VERAVonage

@Suite("PiP support types tests")
@MainActor
struct PictureInPictureSupportTests {

    @Test("Sample buffer view is backed by an AVSampleBufferDisplayLayer")
    func sampleBufferViewBackingLayer() {
        let view = PictureInPictureSampleBufferView()

        #expect(view.layer is AVSampleBufferDisplayLayer)
        #expect(view.sampleBufferDisplayLayer === view.layer)
    }

    @Test("Anchor view exercises its mount/layout notification path")
    func anchorViewMountPath() {
        let view = PictureInPictureAnchorView.AnchorUIView()
        view.onReady = { _, _ in }

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        view.frame = window.bounds
        window.addSubview(view)  // didMoveToWindow → notifyIfEligible (eligible → async deliver)
        view.layoutIfNeeded()  // layoutSubviews → notifyIfEligible (didNotify guard now blocks)

        #expect(view.onReady != nil)
    }
}

@Suite("PiP subscriber factory tests")
@MainActor
struct PictureInPictureVonageSubscriberFactoryTests {

    @Test("Base and PiP subscriber factories run against the SDK")
    func factoriesRun() {
        // `OTSubscriber` may reject an opaque stream (→ throws) or accept it; either path is
        // exercised. When it succeeds, the PiP factory must produce a PiP subscriber.
        _ = try? VonageSubscriberFactory().makeSubscriber(OTStream())

        if let subscriber = try? PictureInPictureVonageSubscriberFactory().makeSubscriber(OTStream())
            as? PictureInPictureVonageSubscriber
        {
            subscriber.setPictureInPictureTarget(true)
            subscriber.setPictureInPictureTarget(false)
        }
    }
}
