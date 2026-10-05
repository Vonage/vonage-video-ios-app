//
//  Created by Vonage on 21/6/26.
//

import AVKit
import Foundation
import UIKit

/// Wraps `AVPictureInPictureController` for Vonage video calls.
@MainActor
final class PictureInPictureController: NSObject {

    private var pipController: AVPictureInPictureController?
    private let sampleBufferVideoCallView = PictureInPictureSampleBufferView()

    /// The renderer that currently sends frames to the PiP layer. Only one renderer may do this at
    /// a time: if two do, the PiP window flickers between participants. The controller tracks the
    /// current one so it always detaches the right renderer before attaching a new one.
    private weak var currentFeedRenderer: PictureInPictureVideoRenderer?

    private(set) var isInPictureInPicture = false
    var isConfigured: Bool { pipController != nil }
    var onPictureInPicturePossibleDidChange: (() -> Void)?
    var onPictureInPictureStateDidStart: (() -> Void)?
    var onPictureInPictureStateDidStop: (() -> Void)?
    var onPictureInPictureFailed: ((Error) -> Void)?

    var isPictureInPictureSupported: Bool {
        AVPictureInPictureController.isPictureInPictureSupported()
    }

    var canStartPictureInPicture: Bool {
        pipController?.isPictureInPicturePossible ?? false
    }

    /// Builds a fresh AVKit controller anchored to `sourceView`, replacing any previous one. The
    /// PiP feed must be (re)attached afterwards via ``attachFeed(to:)``. Must not be called while
    /// PiP is active.
    func configure(with sourceView: UIView) {
        tearDown()

        let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
        pipVideoCallViewController.preferredContentSize = CGSize(width: 640, height: 480)
        pipVideoCallViewController.view.addSubview(sampleBufferVideoCallView)

        sampleBufferVideoCallView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sampleBufferVideoCallView.leadingAnchor.constraint(
                equalTo: pipVideoCallViewController.view.leadingAnchor
            ),
            sampleBufferVideoCallView.trailingAnchor.constraint(
                equalTo: pipVideoCallViewController.view.trailingAnchor
            ),
            sampleBufferVideoCallView.topAnchor.constraint(equalTo: pipVideoCallViewController.view.topAnchor),
            sampleBufferVideoCallView.bottomAnchor.constraint(
                equalTo: pipVideoCallViewController.view.bottomAnchor
            ),
        ])

        let contentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: sourceView,
            contentViewController: pipVideoCallViewController
        )

        pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        pipController?.delegate = self
    }

    func startPictureInPicture() {
        pipController?.startPictureInPicture()
    }

    /// Makes `videoRenderer` the one that feeds the PiP window, detaching the previous renderer.
    /// Does nothing until the AVKit controller is configured.
    func attachFeed(to videoRenderer: PictureInPictureVideoRenderer) {
        guard isConfigured else { return }
        routeFeed(to: videoRenderer)
    }

    /// Detaches the previous renderer and attaches `videoRenderer` to the PiP layer. Separate from
    /// ``attachFeed(to:)`` so it can be unit tested on the simulator, where AVKit cannot create a
    /// controller.
    func routeFeed(to videoRenderer: PictureInPictureVideoRenderer) {
        if currentFeedRenderer !== videoRenderer {
            currentFeedRenderer?.pipBufferDisplayLayer = nil
        }
        currentFeedRenderer = videoRenderer
        videoRenderer.pipBufferDisplayLayer = sampleBufferVideoCallView.sampleBufferDisplayLayer
    }

    func stopPictureInPicture() {
        pipController?.stopPictureInPicture()
    }

    func tearDown() {
        currentFeedRenderer?.pipBufferDisplayLayer = nil
        currentFeedRenderer = nil
        pipController?.delegate = nil
        pipController = nil
        isInPictureInPicture = false
        let layer = sampleBufferVideoCallView.sampleBufferDisplayLayer
        if layer.requiresFlushToResumeDecoding {
            layer.flush()
        }
    }

}

extension PictureInPictureController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerIsPictureInPicturePossibleDidChange(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        onPictureInPicturePossibleDidChange?()
    }

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        isInPictureInPicture = true
        onPictureInPictureStateDidStart?()
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        if sampleBufferVideoCallView.sampleBufferDisplayLayer.requiresFlushToResumeDecoding {
            sampleBufferVideoCallView.sampleBufferDisplayLayer.flush()
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        isInPictureInPicture = false
        onPictureInPictureStateDidStop?()
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        isInPictureInPicture = false
        onPictureInPictureFailed?(error)
        onPictureInPictureStateDidStop?()
    }
}
