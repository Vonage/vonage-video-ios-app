//
//  Created by Vonage on 19/11/26.
//

import CoreMedia
import Foundation

/// Receives screen frames from an in-process capture session.
///
/// `consume` runs on the capture queue and must copy what it needs before returning.
public protocol ScreenShareFrameConsuming: AnyObject {
    func consume(sampleBuffer: CMSampleBuffer)
    func captureWillStart()
    func captureDidStop()
}

/// Starts and stops system screen capture and presents the system content picker.
public protocol ScreenCaptureControlling: AnyObject, Sendable {
    func activate()
    func deactivate()
    func presentPicker()
    func setFrameConsumer(_ consumer: (any ScreenShareFrameConsuming & Sendable)?)
}

/// Builds the in-process capture controller when the OS provides ScreenCaptureKit.
public enum ScreenCaptureControllerFactory {
    public static func make() -> (any ScreenCaptureControlling)? {
        #if os(iOS) && canImport(ScreenCaptureKit)
            if #available(iOS 27, *) {
                return ScreenCaptureKitController()
            }
        #endif
        return nil
    }
}
