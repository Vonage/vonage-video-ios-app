//
//  Created by Vonage on 17/10/26.
//

import SwiftUI

/// Immutable snapshot of the host call state that feeds ``OnTheGoViewModel``.
///
/// The host maps its call state into this value and calls
/// ``OnTheGoViewModel/update(snapshot:)`` every time anything changes.
public struct OnTheGoCallSnapshot: Equatable {

    /// A participant relevant to the On-the-Go UI (currently only the
    /// screen-share participant needs a rendered view).
    public struct Participant: Identifiable, Equatable {
        public let id: String
        public let name: String
        public let isScreenshare: Bool

        /// The participant's rendered video view, non-nil only for the
        /// screen-share participant.
        public let view: AnyView?

        /// Called when ``view`` appears on screen (host should subscribe
        /// to the stream's video).
        public let onAppear: (() -> Void)?

        /// Called when ``view`` disappears (host should unsubscribe).
        public let onDisappear: (() -> Void)?

        public init(
            id: String,
            name: String,
            isScreenshare: Bool,
            view: AnyView? = nil,
            onAppear: (() -> Void)? = nil,
            onDisappear: (() -> Void)? = nil
        ) {
            self.id = id
            self.name = name
            self.isScreenshare = isScreenshare
            self.view = view
            self.onAppear = onAppear
            self.onDisappear = onDisappear
        }

        /// Equality ignores the view and callbacks — they are presentation
        /// details, not identity.
        public static func == (lhs: Participant, rhs: Participant) -> Bool {
            lhs.id == rhs.id && lhs.name == rhs.name && lhs.isScreenshare == rhs.isScreenshare
        }
    }

    /// Whether the call is currently connected.
    public let isConnected: Bool

    /// Whether the local microphone is currently publishing audio.
    public let isMicEnabled: Bool

    /// Whether the local camera is currently publishing video.
    public let isCameraEnabled: Bool

    /// Number of remote participants; the host already excludes screen-share
    /// streams from this count.
    public let participantCount: Int

    /// Display name of the current active speaker, or `nil` when nobody is
    /// speaking.
    public let activeSpeakerName: String?

    /// The screen-share participant when a share is in progress, else `nil`.
    public let screenShareParticipant: Participant?

    public init(
        isConnected: Bool,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        participantCount: Int,
        activeSpeakerName: String?,
        screenShareParticipant: Participant?
    ) {
        self.isConnected = isConnected
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participantCount = participantCount
        self.activeSpeakerName = activeSpeakerName
        self.screenShareParticipant = screenShareParticipant
    }

    /// The empty, not-in-a-call snapshot.
    public static let disconnected = OnTheGoCallSnapshot(
        isConnected: false,
        isMicEnabled: false,
        isCameraEnabled: false,
        participantCount: 0,
        activeSpeakerName: nil,
        screenShareParticipant: nil
    )
}
