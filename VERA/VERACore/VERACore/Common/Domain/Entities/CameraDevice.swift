//
//  Created by Vonage on 9/7/25.
//

import Foundation

/// Categorisation of a camera input for UI purposes.
///
/// The picker uses this to pick a sensible SF Symbol icon. On iPhone/iPad we
/// have `.front` / `.back`. On macOS via "Designed for iPad on Mac", real
/// device types (`.external`, `.continuity`, `.unknown`) become reachable
/// once the SDK enumerates them.
public enum CameraKind: Equatable {
    case front
    case back
    case external
    case continuity
    case unknown
}

public struct CameraDevice {
    public let id: String
    public let name: String
    public let kind: CameraKind

    public init(id: String, name: String, kind: CameraKind = .unknown) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}
