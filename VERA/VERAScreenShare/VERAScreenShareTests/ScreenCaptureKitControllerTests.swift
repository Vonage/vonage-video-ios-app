//
//  Created by Vonage on 20/11/26.
//

import CoreMedia
import Foundation
import Testing
import os

@testable import VERAScreenShare

@Suite("Screen share UI bridge")
struct ScreenShareUIBridgeTests {
    @Test("present runs the installed hook")
    @MainActor
    func presentRunsTheInstalledHook() {
        var calls = 0
        ScreenShareUIBridge.shared.presentSystemPicker = { calls += 1 }
        ScreenShareUIBridge.shared.present()
        #expect(calls == 1)
        ScreenShareUIBridge.shared.presentSystemPicker = nil
        ScreenShareUIBridge.shared.present()
        #expect(calls == 1)
    }
}

#if canImport(ScreenCaptureKit)
    import ScreenCaptureKit

    @Suite("Screen capture controller", .serialized)
    struct ScreenCaptureKitControllerTests {
        @Test("Activation is idempotent and deactivation stops the consumer once")
        func activateThenDeactivateStopsTheConsumer() {
            guard #available(iOS 27, macOS 14.6, *) else { return }
            let controller = ScreenCaptureKitController()
            let consumer = CaptureEventSpy()
            controller.setFrameConsumer(consumer)
            let picker = SCContentSharingPicker.shared
            let wasActive = picker.isActive
            picker.isActive = false
            controller.presentPicker()
            picker.isActive = wasActive
            controller.activate()
            controller.activate()
            controller.deactivate()
            controller.deactivate()
            #expect(consumer.stopped == 1)
        }

        @Test("A picker start failure stops the consumer")
        func startFailureStopsTheConsumer() async {
            guard #available(iOS 27, macOS 14.6, *) else { return }
            let controller = ScreenCaptureKitController()
            let consumer = CaptureEventSpy()
            controller.setFrameConsumer(consumer)
            controller.activate()
            controller.contentSharingPicker(
                SCContentSharingPicker.shared,
                didCancelFor: nil)
            controller.contentSharingPickerStartDidFailWithError(
                NSError(
                    domain: SCStreamErrorDomain,
                    code: SCStreamError.Code.userStopped.rawValue))
            await flushMain()
            controller.contentSharingPickerStartDidFailWithError(
                NSError(domain: SCStreamErrorDomain, code: -3821))
            await flushMain()
            controller.contentSharingPickerStartDidFailWithError(
                NSError(domain: "OtherDomain", code: 1))
            await flushMain()
            #expect(consumer.stopped >= 1)
            controller.deactivate()
        }

        @Test("Activation from a background queue still reaches the picker")
        func activateFromBackgroundQueue() async {
            guard #available(iOS 27, macOS 14.6, *) else { return }
            let controller = ScreenCaptureKitController()
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    controller.activate()
                    continuation.resume()
                }
            }
            controller.deactivate()
        }
    }

    private final class CaptureEventSpy: ScreenShareFrameConsuming, @unchecked Sendable {
        private let lock = OSAllocatedUnfairLock(initialState: 0)
        var stopped: Int { lock.withLock { $0 } }

        func consume(sampleBuffer: CMSampleBuffer) {
            // These tests only count stop events.
        }

        func captureWillStart() {
            // These tests only count stop events.
        }

        func captureDidStop() {
            lock.withLock { $0 += 1 }
        }
    }

    private func flushMain() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
#endif
