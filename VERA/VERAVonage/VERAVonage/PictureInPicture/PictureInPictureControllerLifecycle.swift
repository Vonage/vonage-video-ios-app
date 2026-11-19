import Foundation

/// Value events shared by the Objective-C adapter and the lifecycle state machine.
enum PictureInPictureControllerEvent: Sendable {
    case possibleChanged
    case willStart
    case didStart
    case didStop
    case failed(any Error)
}

/// UI-owned lifecycle state, independent of AVKit availability on the running device.
/// The controller's queue supplies ordered events in bounded batches; identity changes retire
/// previous controllers, and queue reactivation drops events from a prior configured lifetime.
@MainActor
final class PictureInPictureControllerLifecycle {
    private var controllerID: ObjectIdentifier?
    private var generation: UInt64 = 0
    private(set) var isInPictureInPicture = false
    var onPossibleDidChange: (() -> Void)?
    var onStateDidStart: (() -> Void)?
    var onDidStartRendering: (() -> Void)?
    var onStateDidStop: (() -> Void)?
    var onFailed: ((Error) -> Void)?

    func activate(controllerID: ObjectIdentifier?) {
        generation &+= 1
        self.controllerID = controllerID
        isInPictureInPicture = false
    }

    func receive(_ event: PictureInPictureControllerEvent, controllerID: ObjectIdentifier) {
        guard let activeControllerID = self.controllerID, activeControllerID == controllerID else { return }
        let deliveryGeneration = generation
        switch event {
        case .possibleChanged: onPossibleDidChange?()
        case .willStart:
            isInPictureInPicture = true
            onStateDidStart?()
        case .didStart: onDidStartRendering?()
        case .didStop:
            isInPictureInPicture = false
            onStateDidStop?()
        case .failed(let error):
            isInPictureInPicture = false
            onFailed?(error)
            guard generation == deliveryGeneration else { return }
            onStateDidStop?()
        }
    }
}
