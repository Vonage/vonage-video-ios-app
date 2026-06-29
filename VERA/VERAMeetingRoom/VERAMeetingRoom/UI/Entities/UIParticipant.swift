//
//  Created by Vonage on 17/3/26.
//

import SwiftUI
import VERADomain

/// A display-ready participant model for use in SwiftUI meeting room views.
///
/// Wraps the domain ``Participant`` and adds UI-only state such as ``isPinned``.
/// This separation keeps pin state out of the domain layer.
public struct UIParticipant: Identifiable, Equatable, Hashable {
    /// The underlying domain participant.
    public let participant: Participant
    /// Whether this participant is pinned in the UI.
    public let isPinned: Bool
    /// Whether this participant is the current Picture-in-Picture target tile.
    public let isPictureInPictureTarget: Bool
    /// Whether this participant can be pinned.
    public let canBePinned: Bool
    /// Whether this participant can be pinned or unpinned.
    public var canTogglePinState: Bool { (canBePinned || isPinned) && participant.isRemote }
    /// Toggle the pin state
    public var onTogglePin: (() -> Void)?

    public init(
        participant: Participant,
        isPinned: Bool = false,
        isPictureInPictureTarget: Bool = false,
        canBePinned: Bool = false
    ) {
        self.participant = participant
        self.isPinned = isPinned
        self.isPictureInPictureTarget = isPictureInPictureTarget
        self.canBePinned = canBePinned
    }

    // MARK: - Delegated Properties

    public var id: String { participant.id }
    public var connectionId: String? { participant.connectionId }
    public var name: String { participant.name }
    public var isMicEnabled: Bool { participant.isMicEnabled }
    public var isCameraEnabled: Bool { participant.isCameraEnabled }
    public var view: AnyView { participant.view }
    public var videoDimensions: CGSize { participant.videoDimensions }
    public var isRemote: Bool { participant.isRemote }
    public var creationTime: Date { participant.creationTime }
    public var isScreenshare: Bool { participant.isScreenshare }
    public var containerAspectRatio: Double { participant.containerAspectRatio }
    public var aspectRatio: Double { participant.aspectRatio }
    public var audioLevel: Float { participant.audioLevel }
    public var isProminent: Bool { participant.isScreenshare || isPinned }
    public var onAppear: (() -> Void)? { participant.onAppear }
    public var onDisappear: (() -> Void)? { participant.onDisappear }

    // MARK: - Equatable

    public static func == (lhs: UIParticipant, rhs: UIParticipant) -> Bool {
        lhs.participant == rhs.participant && lhs.isPinned == rhs.isPinned
            && lhs.isPictureInPictureTarget == rhs.isPictureInPictureTarget
            && lhs.canBePinned == rhs.canBePinned
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(participant)
        hasher.combine(isPinned)
        hasher.combine(isPictureInPictureTarget)
        hasher.combine(canBePinned)
    }
}
