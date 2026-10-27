//
//  Created by Vonage on 21/6/26.
//

import AVKit
import Foundation
import UIKit

/// Wraps `AVPictureInPictureController` for Vonage video calls.
@MainActor
final class PictureInPictureController: NSObject {

    private struct Callback: Sendable {
        let controllerID: ObjectIdentifier
        let event: PictureInPictureControllerEvent
    }
    nonisolated private let callbacks: MainActorEventQueue<Callback>
    private let lifecycle = PictureInPictureControllerLifecycle()

    override init() {
        callbacks = MainActorEventQueue()
        super.init()
        lifecycle.onDidStartRendering = { [weak self] in
            guard let renderer = self?.sampleBufferVideoCallView.sampleBufferDisplayLayer.sampleBufferRenderer else {
                return
            }
            if renderer.requiresFlushToResumeDecoding { renderer.flush() }
        }
        configureCallbackDelivery()
    }

    private func configureCallbackDelivery() {
        callbacks.activate { [weak self] callback in
            self?.lifecycle.receive(callback.event, controllerID: callback.controllerID)
        }
    }

    private var pipController: AVPictureInPictureController?
    private let sampleBufferVideoCallView = PictureInPictureSampleBufferView()

    private weak var currentFeedRenderer: PictureInPictureVideoRenderer?

    var isInPictureInPicture: Bool { lifecycle.isInPictureInPicture }
    var isConfigured: Bool { pipController != nil }
    var onPictureInPicturePossibleDidChange: (() -> Void)? {
        get { lifecycle.onPossibleDidChange }
        set { lifecycle.onPossibleDidChange = newValue }
    }
    var onPictureInPictureStateDidStart: (() -> Void)? {
        get { lifecycle.onStateDidStart }
        set { lifecycle.onStateDidStart = newValue }
    }
    var onPictureInPictureStateDidStop: (() -> Void)? {
        get { lifecycle.onStateDidStop }
        set { lifecycle.onStateDidStop = newValue }
    }
    var onPictureInPictureFailed: ((Error) -> Void)? {
        get { lifecycle.onFailed }
        set { lifecycle.onFailed = newValue }
    }

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
        lifecycle.activate(controllerID: pipController.map { ObjectIdentifier($0) })
        configureCallbackDelivery()
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        pipController?.delegate = self
    }

    func startPictureInPicture() {
        pipController?.startPictureInPicture()
    }

    /// Re-points the running PiP sample-buffer layer at a different renderer's feed (used when the
    /// PiP target changes between renderers while PiP stays active — e.g. publisher ↔ remote).
    func attachFeed(to videoRenderer: PictureInPictureVideoRenderer) {
        guard isConfigured else { return }
        routeFeed(to: videoRenderer)
    }

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
        callbacks.invalidate()
        currentFeedRenderer?.pipBufferDisplayLayer = nil
        currentFeedRenderer = nil
        pipController?.delegate = nil
        pipController = nil
        lifecycle.activate(controllerID: nil)
        let renderer = sampleBufferVideoCallView.sampleBufferDisplayLayer.sampleBufferRenderer
        if renderer.requiresFlushToResumeDecoding {
            renderer.flush()
        }
    }

}

extension PictureInPictureController: AVPictureInPictureControllerDelegate {
    nonisolated func pictureInPictureControllerIsPictureInPicturePossibleDidChange(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        callbacks.send(Callback(controllerID: ObjectIdentifier(pictureInPictureController), event: .possibleChanged))
    }

    nonisolated func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        callbacks.send(Callback(controllerID: ObjectIdentifier(pictureInPictureController), event: .willStart))
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        callbacks.send(Callback(controllerID: ObjectIdentifier(pictureInPictureController), event: .didStart))
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        callbacks.send(Callback(controllerID: ObjectIdentifier(pictureInPictureController), event: .didStop))
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        // This existing response touches no UI state and stays on the caller's executor.
        completionHandler(true)
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        callbacks.send(Callback(controllerID: ObjectIdentifier(pictureInPictureController), event: .failed(error)))
    }
}
