//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Combine
import Foundation
import OpenTok
import VERACore
import VERADomain

/// Legacy stable IDs for the iPhone/iPad front and back cameras.
///
/// Kept so previously-hardcoded call sites (e.g. older snapshot fixtures, tests)
/// that still pass `"Front"` / `"Back"` continue to resolve. New code should
/// flow real `AVCaptureDevice.uniqueID` strings through instead.
enum VonageCameraDevice: String {
    case front = "Front"
    case back = "Back"
}

public final class VonageCameraDevicesRepository: CameraDevicesRepository {
    private let _observeAvailableDevices = CurrentValueSubject<[VERACore.CameraDevice], Never>([])
    public lazy var observeAvailableDevices: AnyPublisher<[VERACore.CameraDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    private let publisherRepository: PublisherRepository

    public init(publisherRepository: PublisherRepository) {
        self.publisherRepository = publisherRepository
    }

    /// Enumerates real camera devices visible to AVFoundation and publishes
    /// them to subscribers.
    ///
    /// On iPhone/iPad this returns the front + back built-in cameras (and
    /// any external/Continuity cameras present, iOS 17+).
    /// Under "Designed for iPad on Mac" this returns whatever the Mac exposes:
    /// built-in iSight, Studio Display webcam, external USB, Continuity Camera.
    ///
    /// The SDK uses the same `AVCaptureDevice.DiscoverySession` underneath, so
    /// the `id` strings we publish are stable `AVCaptureDevice.uniqueID` values
    /// that line up with `OTPublisher.availableCameraDevices`.
    public func loadCameraDevices() {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: Self.discoveryDeviceTypes,
            mediaType: .video,
            position: .unspecified
        )

        let devices: [VERACore.CameraDevice] = session.devices.map { avDevice in
            VERACore.CameraDevice(
                id: avDevice.uniqueID,
                name: avDevice.localizedName,
                kind: Self.cameraKind(for: avDevice)
            )
        }

        if devices.isEmpty {
            // Fallback for unit-test processes where AVFoundation may return
            // no cameras: preserve the historic front/back placeholders so
            // existing fixtures keep working.
            _observeAvailableDevices.value = [
                VERACore.CameraDevice(
                    id: VonageCameraDevice.front.rawValue,
                    name: "Front Camera",
                    kind: .front),
                VERACore.CameraDevice(
                    id: VonageCameraDevice.back.rawValue,
                    name: "Back Camera",
                    kind: .back),
            ]
        } else {
            _observeAvailableDevices.value = devices
        }
    }

    // MARK: - Helpers

    private static var discoveryDeviceTypes: [AVCaptureDevice.DeviceType] {
        var types: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera
        ]
        if #available(iOS 17.0, *) {
            types.append(contentsOf: [
                .external,
                .continuityCamera,
            ])
        }
        return types
    }

    private static func cameraKind(for device: AVCaptureDevice) -> CameraKind {
        if #available(iOS 17.0, *) {
            if device.deviceType == .continuityCamera { return .continuity }
            if device.deviceType == .external { return .external }
        }
        switch device.position {
        case .front: return .front
        case .back: return .back
        default: return .unknown
        }
    }
}
