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

    private(set) var isInPictureInPicture = false
    var isConfigured: Bool { pipController != nil }
    var onPictureInPicturePossibleDidChange: (() -> Void)?
    var onPictureInPictureStateDidChange: ((Bool) -> Void)?
    var onPictureInPictureFailed: ((Error) -> Void)?

    var isPictureInPictureSupported: Bool {
        AVPictureInPictureController.isPictureInPictureSupported()
    }

    var canStartPictureInPicture: Bool {
        pipController?.isPictureInPicturePossible ?? false
    }

    @discardableResult
    func configureIfNeeded(
        with sourceView: UIView,
        videoRenderer: PictureInPictureVideoRenderer,
        videoFrame: CGRect
    ) -> Bool {
        guard !isInPictureInPicture else { return false }
        guard pipController == nil else { return false }

        videoRenderer.pipBufferDisplayLayer = sampleBufferVideoCallView.sampleBufferDisplayLayer
        videoRenderer.pipBufferDisplayLayer?.frame = videoFrame

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
        return true
    }

    func startPictureInPicture() {
        pipController?.startPictureInPicture()
    }

    func stopPictureInPicture() {
        pipController?.stopPictureInPicture()
    }

    func tearDown() {
        pipController?.delegate = nil
        pipController = nil
        isInPictureInPicture = false
        let layer = sampleBufferVideoCallView.sampleBufferDisplayLayer
        if layer.requiresFlushToResumeDecoding {
            layer.flush()
        }
    }

    /// Tears down and creates a fresh PiP controller for the same source view.
    @discardableResult
    func reconfigure(
        with sourceView: UIView,
        videoRenderer: PictureInPictureVideoRenderer,
        videoFrame: CGRect
    ) -> Bool {
        guard !isInPictureInPicture else { return false }
        tearDown()
        return configureIfNeeded(with: sourceView, videoRenderer: videoRenderer, videoFrame: videoFrame)
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
        onPictureInPictureStateDidChange?(true)
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
        onPictureInPictureStateDidChange?(false)
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
        onPictureInPictureStateDidChange?(false)
    }
}
