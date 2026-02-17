//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

/// A value representing a participant in a call, including media state and a renderable view.
///
/// `Participant` is the domain model used across UI and Vonage wrappers (publisher/subscriber).
/// It encapsulates the participant’s identifiers, media flags, sizing information, and a SwiftUI
/// `view` for rendering. It optionally carries visibility callbacks (`onAppear`/`onDisappear`)
/// to support bandwidth optimization strategies.
///
/// ## Overview
///
/// Use this type to:
/// - Render participant video via ``view``
/// - Reflect mic/camera state in UI
/// - Compute aspect ratios for layout
/// - Track whether a participant is local (`isRemote == false`) or remote
/// - Wire visibility callbacks for subscription control
public struct Participant: Identifiable, Hashable, Equatable, CustomStringConvertible {
    /// Stable identifier for the participant (stream ID, publisher ID, etc.).
    public let id: String
    /// The connection identifier from the Vonage session, used for signal sender resolution.
    public let connectionId: String?
    /// Display name shown in UI.
    public let name: String
    /// Whether the participant’s microphone is enabled.
    public let isMicEnabled: Bool
    /// Whether the participant’s camera is enabled.
    public let isCameraEnabled: Bool
    /// A SwiftUI-compatible view used to render the participant’s video.
    public let view: AnyView
    /// The raw video dimensions used for ratio calculations and layout.
    public let videoDimensions: CGSize
    /// `true` when the participant is remote; `false` for the local publisher.
    public let isRemote: Bool
    /// Creation timestamp for ordering or diagnostics.
    public let creationTime: Date
    /// `true` when the participant is sharing their screen.
    public let isScreenshare: Bool
    /// `true` when the participant is pinned (e.g., highlighted in layout).
    public let isPinned: Bool

    /// Optional callback invoked when this participant’s view appears on screen.
    ///
    /// Use to enable video subscription for remote participants when visible.
    public var onAppear: (() -> Void)?
    /// Optional callback invoked when this participant’s view disappears from screen.
    ///
    /// Use to disable video subscription for remote participants when hidden.
    public var onDisappear: (() -> Void)?

    /// Creates a new participant value.
    ///
    /// - Parameters:
    ///   - id: Stable identifier for the participant.
    ///   - name: Display name.
    ///   - isMicEnabled: `true` if mic is enabled.
    ///   - isCameraEnabled: `true` if camera is enabled.
    ///   - videoDimensions: Raw video dimensions for layout calculations.
    ///   - isRemote: `true` if remote; `false` if local publisher. Defaults to `true`.
    ///   - creationTime: Creation timestamp.
    ///   - isScreenshare: `true` if the participant is screensharing.
    ///   - isPinned: `true` if pinned in UI.
    ///   - view: SwiftUI-compatible video view.
    public init(
        id: String,
        connectionId: String? = nil,
        name: String,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        videoDimensions: CGSize,
        isRemote: Bool = true,
        creationTime: Date,
        isScreenshare: Bool,
        isPinned: Bool,
        view: AnyView
    ) {
        self.id = id
        self.connectionId = connectionId
        self.name = name
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.videoDimensions = videoDimensions
        self.isRemote = isRemote
        self.creationTime = creationTime
        self.isScreenshare = isScreenshare
        self.isPinned = isPinned
        self.view = view
    }

    /// Returns a copy of this participant with an empty view.
    ///
    /// Useful during teardown to release UI resources while retaining metadata.
    public var withEmptyView: Participant {
        Participant(
            id: id,
            connectionId: connectionId,
            name: name,
            isMicEnabled: isMicEnabled,
            isCameraEnabled: isCameraEnabled,
            videoDimensions: videoDimensions,
            isRemote: isRemote,
            creationTime: creationTime,
            isScreenshare: isScreenshare,
            isPinned: isPinned,
            view: AnyView(EmptyView()))
    }

    /// Equality comparing identity and core properties.
    ///
    /// Excludes visibility callbacks from equality.
    public static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id && lhs.connectionId == rhs.connectionId && lhs.name == rhs.name
            && lhs.isMicEnabled == rhs.isMicEnabled
            && lhs.isCameraEnabled == rhs.isCameraEnabled && lhs.videoDimensions == rhs.videoDimensions
            && lhs.isRemote == rhs.isRemote
            && lhs.creationTime == rhs.creationTime
            && lhs.isScreenshare == rhs.isScreenshare
            && lhs.isPinned == rhs.isPinned
    }

    /// Hashes identity and core properties for set/dictionary usage.
    ///
    /// Excludes visibility callbacks from hashing.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(connectionId)
        hasher.combine(name)
        hasher.combine(isMicEnabled)
        hasher.combine(isCameraEnabled)
        hasher.combine(videoDimensions.width)
        hasher.combine(videoDimensions.height)
        hasher.combine(isRemote)
        hasher.combine(creationTime)
        hasher.combine(isScreenshare)
        hasher.combine(isPinned)
    }

    /// Aspect ratio to use for container sizing, with safe defaults.
    ///
    /// - Returns: A ratio suitable for laying out the participant’s view.
    /// - Behavior:
    ///   - If height is zero, returns a default of `16:9`
    ///   - If the ratio is less than 1 (portrait), normalizes to `4:3` (≈1.33)
    public var containerAspectRatio: Double {
        let dimensions = videoDimensions
        guard dimensions.height > 0 else { return 16.0 / 9.0 }
        var ratio = Double(dimensions.width / dimensions.height)
        if ratio < 1 {
            ratio = 1.33
        }
        return ratio
    }

    /// The raw aspect ratio derived from the video dimensions.
    ///
    /// Returns `16:9` if height is zero to avoid division by zero.
    public var aspectRatio: Double {
        guard videoDimensions.height > 0 else { return 16.0 / 9.0 }
        return Double(videoDimensions.width / videoDimensions.height)
    }

    // MARK: - CustomStringConvertible

    /// Human-readable description for logging and diagnostics.
    public var description: String {
        return """
            Participant(id: "\(id)", name: "\(name)", isMicEnabled: \(isMicEnabled), \
            isCameraEnabled: \(isCameraEnabled) \
            isRemote: \(isRemote), isScreenshare: \(isScreenshare), \
            isPinned: \(isPinned))
            """
    }
}
