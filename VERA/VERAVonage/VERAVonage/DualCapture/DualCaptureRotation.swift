//
//  Created by Vonage on 1/11/26.
//

import Foundation
import UIKit

/// Upright rotation for a multi-camera connection, in degrees.
///
/// The value is Sendable so the main thread can read the device orientation and the
/// session queue can apply it without sharing UIKit objects.
enum DualCaptureRotation {
    static func angle(for orientation: UIDeviceOrientation) -> CGFloat? {
        switch orientation {
        case .portrait: 90
        case .portraitUpsideDown: 270
        case .landscapeLeft: 180
        case .landscapeRight: 0
        default: nil
        }
    }
}

/// Forwards device orientation to the capture session.
///
/// UIDevice is main-actor isolated. This watcher is only started and stopped on the main
/// thread, and the angle callback receives a Sendable number.
final class DualCaptureOrientationWatcher: @unchecked Sendable {
    private let lock = NSLock()
    private var observer: NSObjectProtocol?
    private var onAngle: (@Sendable (CGFloat) -> Void)?

    @MainActor
    func start(onAngle: @escaping @Sendable (CGFloat) -> Void) {
        stopGenerating()
        lock.withLock { self.onAngle = onAngle }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.emitCurrentAngle()
            }
        }
        emitCurrentAngle()
    }

    @MainActor
    func stop() {
        stopGenerating()
    }

    @MainActor
    private func emitCurrentAngle() {
        guard let angle = DualCaptureRotation.angle(for: UIDevice.current.orientation) else { return }
        let handler = lock.withLock { onAngle }
        handler?(angle)
    }

    @MainActor
    private func stopGenerating() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        lock.withLock { onAngle = nil }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}
