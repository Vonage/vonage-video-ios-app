//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// A single motion-activity reading, decoupled from `CMMotionActivity` so the
/// domain layer never imports CoreMotion.
public struct MotionSample: Equatable, Sendable {

    /// The kind of physical activity detected.
    public enum Kind: Sendable {
        case stationary
        case walking
        case running
        case cycling
        case automotive
        case unknown
    }

    /// Confidence of the reading. Mirrors `CMMotionActivityConfidence` without
    /// depending on CoreMotion.
    public enum Confidence: Sendable {
        case low
        case medium
        case high
    }

    public let kind: Kind
    public let confidence: Confidence
    public let timestamp: Date

    public init(kind: Kind, confidence: Confidence, timestamp: Date) {
        self.kind = kind
        self.confidence = confidence
        self.timestamp = timestamp
    }

    /// Whether this sample counts as motion. Low-confidence readings never do.
    public var isMoving: Bool {
        confidence != .low && [.walking, .running, .cycling, .automotive].contains(kind)
    }
}

/// Authorization status for motion & fitness access, decoupled from
/// `CMAuthorizationStatus` so the domain layer never imports CoreMotion.
public enum MotionAuthorizationStatus: Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case unavailable
}
